-- This script contains the data processing sentences to be executed inside the previously created and populated database for the determination of isolated buildings exposed to wildfires

-- This process assumes that the SIOSE polygons exposed to forest fires in the study area have been previously obtained through the "wui.sql" script

-- Pointcloud extension is used for lidar data processing

CREATE EXTENSION pointcloud;
CREATE EXTENSION pointcloud_postgis;

-- Obtaining lidar points for intermix situation assessment

CREATE MATERIALIZED VIEW intermix_points (id, id_polygon, geom, class) AS (
WITH intermix_h25 AS (
SELECT a.id_polygon, a.geom, b.h25
FROM wui.intermix_polygons a JOIN hojas25k b ON a.geom && b.wkb_geometry
GROUP BY 1,2,3),
intermix_patch(id_polygon, pa) AS (
SELECT a.id_polygon, pc_filterbetween(b.pa, 'Classification', 3, 7)
FROM intermix_h25 a JOIN lidar b ON pc_intersects(a.geom,b.pa)
WHERE a.h25=b.h25),
intermix_pt (id_polygon, pt) AS (
SELECT id_polygon, pc_explode(pa)
FROM intermix_patch)
SELECT row_number() over(), id_polygon,pt::geometry,pc_get(pt, 'Classification')
FROM intermix_pt);

-- Obtaining lidar points for interface situation assessment (Only polygons whose prevalent exposure was of level 3 (100 m interface) were considered)
-- Because of the nature of this typology for this case the buildings and fuel corresponding points were obtained independently

-- Obtaining lidar buildings points for interface situation assessment
CREATE MATERIALIZED VIEW pop_points (id, id_polygon, geom, class) AS (
WITH pop (id_polygon, geom) AS(
SELECT a.pop_polygon, b.geom
FROM wui.interface3 a NATURAL JOIN wui.residentialpolygons b),
pop_h25 (id_polygon, geom) AS (
SELECT a.id_polygon, a.geom, b.h25 FROM pop a JOIN hojas25k b ON a.geom && b.wkb_geometry GROUP BY 1,2,3),
pop_patch (id_polygon, pa) AS (
SELECT a.id_polygon, pc_filterequals(b.pa, 'Classification', 6)
FROM pop_h25 a JOIN lidar b ON pc_intersects(a.geom::geometry,b.pa)
WHERE a.h25=b.h25),
pop_pt (id_polygon, pt) AS (
SELECT id_polygon, pc_explode(pa)
FROM pop_patch)
SELECT row_number() over(), id_polygon,pt::geometry, pc_get(pt, 'Classification')
FROM pop_pt);

-- Obtaining lidar fuel points for interface situation assessment
CREATE MATERIALIZED VIEW fuel_points (id, id_polygon, geom, class) AS (
WITH fuel (id_polygon, geom) AS(
SELECT a.fuel_polygon, b.geom
FROM wui.interface3 a NATURAL JOIN wui.fuelpolygons b
GROUP BY 1,2),
fuel_h25 (id_polygon, geom) AS (
SELECT a.id_polygon, a.geom, b.h25
FROM fuel a JOIN hojas25k b ON a.geom && b.wkb_geometry
GROUP BY 1,2,3),
fuel_patch (id_polygon, pa) AS (
SELECT a.id_polygon, pc_filterbetween(b.pa, 'Classification', 3, 6)
FROM fuel_h25 a JOIN lidar b ON pc_intersects(a.geom::geometry,b.pa)
WHERE a.h25=b.h25),
fuel_pt (id_polygon, pt) AS (
SELECT id_polygon, pc_explode(pa)
FROM fuel_patch)
SELECT row_number() over(), id_polygon,pt::geometry,pc_get(pt, 'Classification')
FROM fuel_pt);

-- Coordinate system transformation for clustering
CREATE MATERIALIZED VIEW public.intermix_points_25830 AS
 SELECT intermix_points.id,
    intermix_points.id_polygon,
    public.st_transform(public.st_setsrid(intermix_points.geom, 4258), 25830) AS geom,
    intermix_points.class
   FROM public.intermix_points;
   
CREATE MATERIALIZED VIEW public.fuel_points_25830 AS
 SELECT fuel_points.id,
    fuel_points.id_polygon,
    public.st_transform(public.st_setsrid(fuel_points.geom, 4258), 25830) AS geom,
    fuel_points.class
   FROM public.fuel_points;

CREATE MATERIALIZED VIEW public.pop_points_25830 AS
 SELECT pop_points.id,
    pop_points.id_polygon,
    public.st_transform(public.st_setsrid(pop_points.geom, 4258), 25830) AS geom,
    pop_points.class
   FROM public.pop_points;   

-- Intermix clusters
CREATE MATERIALIZED VIEW intermix_clusters (id, id_polygon, geom, is_fuel) AS (
WITH pop_clusters (id_polygon, geom, is_fuel) AS (
SELECT id_polygon, st_astext(unnest(c_list)), FALSE
FROM (
SELECT id_polygon, st_clusterwithin(geom, 5) c_list
FROM intermix_points_25830
WHERE class=6
GROUP BY 1) sel_pop),
fuel_clusters (id_polygon, geom, is_fuel) AS (
SELECT id_polygon, st_astext(unnest(c_list)), TRUE
FROM (
SELECT id_polygon, st_clusterwithin(geom, 5) c_list
FROM intermix_points_25830
WHERE class!=6
GROUP BY 1) sel_fuel)
SELECT row_number() over(), * FROM (SELECT * FROM pop_clusters UNION ALL SELECT * FROM fuel_clusters) union_clusters);

-- Interface buildings clusters
CREATE MATERIALIZED VIEW interface3_pop_clusters (id, pop_polygon, geom) AS (
WITH pop_clus_geom (id_polygon, geom) AS(
SELECT id_polygon, st_astext(unnest(c_list))
FROM (SELECT id_polygon, st_clusterwithin(geom, 5) c_list
FROM pop_points_25830
GROUP BY 1) sel_pop)
SELECT row_number() over(), * FROM pop_clus_geom
);

-- Interface fuel clusters
CREATE MATERIALIZED VIEW interface3_fuel_clusters (id, fuel_polygon, geom) AS (
WITH fuel_clus_geom (id_polygon, geom) AS(
SELECT id_polygon, st_astext(unnest(c_list))
FROM (SELECT id_polygon, st_clusterwithin(geom, 5) c_list
FROM fuel_points_25830
GROUP BY 1) sel_fuel)
SELECT row_number() over(), * FROM fuel_clus_geom
);

-- Configuration table creation for clusters filtering
CREATE TABLE cluster_cfg (id_cluster int, cluster_num_points int);
INSERT INTO cluster_cfg VALUES (521808, 25);

-- Intermix clusters filtering
CREATE MATERIALIZED VIEW intermix_clusters_filtered (id,id_polygon, geom, is_fuel) AS (
WITH intermix_polygons_25830 (id_polygon, geom) AS(
SELECT id_polygon, st_transform(geom, 25830)
FROM wui.intermix_polygons),
intermix_clusters_multi (id,id_polygon, geom, is_fuel) AS(
SELECT id,
id_polygon,
st_setsrid(st_collectionhomogenize(geom),25830),
is_fuel
FROM intermix_clusters)
SELECT row_number() over(), a.id_polygon, st_setsrid(a.geom,25830), is_fuel
FROM intermix_clusters_multi a JOIN intermix_polygons_25830 b ON st_intersects(a.geom, b.geom)
WHERE st_numgeometries(a.geom)>=(SELECT cluster_num_points
FROM cluster_cfg LIMIT 1)
);

-- Interface buildings clusters filtering
CREATE MATERIALIZED VIEW interface3_pop_clusters_filtered (id, pop_polygon, geom) AS (
WITH interface3_pop_25830 (id_polygon, geom) AS(
SELECT id_polygon, st_transform(geom, 25830)
FROM wui.interface_polygons
WHERE prevalent_exposure=3),
interface3_pop_clusters_multi (id, pop_polygon, geom) AS(
SELECT id,
pop_polygon,
st_setsrid(st_collectionhomogenize(geom),25830)
FROM interface3_pop_clusters)
SELECT row_number() over(), a.id_polygon, st_setsrid(b.geom,25830)
FROM interface3_pop_25830 a JOIN interface3_pop__clusters_multi b ON st_intersects(a.geom, b.geom)
WHERE st_numgeometries(b.geom)>=(SELECT cluster_num_points
FROM cluster_cfg LIMIT 1)
);

-- Interface fuel clusters filtering
CREATE MATERIALIZED VIEW interface3_fuel_clusters_filtered (id,fuel_polygon, geom) AS (
WITH interface3_fuel_25830 (id_polygon, geom) AS(
SELECT a.fuel_polygon, st_transform(b.geom::geometry, 25830)
FROM wui.interface3 a JOIN wui.fuelpolygons b ON (a.fuel_polygon=b.id_polygon) GROUP BY 1,2),
interface3_fuel_clusters_multi (id,fuel_polygon, geom) AS(
SELECT id,
fuel_polygon,
st_setsrid(st_collectionhomogenize(geom),25830)
FROM interface3_fuel_clusters)
SELECT row_number() over(), a.fuel_polygon, st_setsrid(a.geom,25830)
FROM interface3_fuel_clusters_multi a JOIN interface3_fuel_25830 b ON st_intersects(a.geom, b.geom)
WHERE st_numgeometries(a.geom)>=(SELECT cluster_num_points
FROM cluster_cfg LIMIT 1)
);

-- Exposure assessment for intermix buildings clusters
CREATE MATERIALIZED VIEW intermix_clusters_eval (id_cluster, id_polygon, geom, fuel_min_distance, is_intermix) AS (
WITH pop_clusters (id, id_polygon, geom) AS(
SELECT id, id_polygon, geom
FROM intermix_clusters_filtered
WHERE is_fuel=FALSE),
fuel_clusters (id, id_polygon, geom) AS(
SELECT id, id_polygon, geom
FROM intermix_clusters_filtered
WHERE is_fuel=TRUE)
SELECT a.id, a.id_polygon, a.geom, min(st_distance(a.geom, b.geom)), CASE WHEN min(st_distance(a.geom, b.geom))<=100 THEN TRUE ELSE FALSE END
FROM pop_clusters a JOIN fuel_clusters b ON a.id_polygon=b.id_polygon
GROUP BY 1,2,3
);

-- Exposure assessment for interface buildings clusters
CREATE MATERIALIZED VIEW interface_clusters_eval (id_cluster, id_polygon, geom, fuel_min_distance, is_interface) AS (
SELECT a.id, a.pop_polygon, a.geom, min(st_distance(a.geom, b.geom)), CASE WHEN min(st_distance(a.geom, b.geom))<=100 THEN TRUE ELSE FALSE END
FROM interface3_pop_clusters_filtered a, interface3_fuel_clusters_filtered b, wui.interface3 c
WHERE a.pop_polygon=c.pop_polygon AND b.fuel_polygon=c.fuel_polygon GROUP BY 1,2,3);

-- Comparison between results of use of information from SIOSE versus use of information from SIOSE and LiDAR for intermix
CREATE MATERIALIZED VIEW intermix_polygons_eval (id_polygon, total_pop, exposed_pop, non_exposed_pop, accuracy, is_intermix, geom) AS (
WITH summary (id_polygon, total_pop, exposed_pop, non_exposed_pop, accuracy) AS(
SELECT id_polygon, COUNT(*), sum(is_intermix::integer), COUNT(*) - sum(is_intermix::integer), trunc((sum(is_intermix::integer)::decimal/COUNT(*)), 3)
FROM intermix_clusters_eval
GROUP BY 1)
SELECT a.id_polygon, coalesce(b.total_pop, 0), coalesce(b.exposed_pop, 0), coalesce(b.non_exposed_pop,0), coalesce(b.accuracy,0), CASE WHEN b.total_pop>=1 THEN TRUE ELSE FALSE END, a.geom
FROM wui.intermix_polygons a LEFT OUTER JOIN summary b ON a.id_polygon=b.id_polygon
);

-- Comparison between results of use of information from SIOSE versus use of information from SIOSE and LiDAR for interface
CREATE MATERIALIZED VIEW interface_polygons_eval (id_polygon, total_pop, exposed_pop, non_exposed_pop, accuracy, is_interface, geom) AS (
WITH summary (id_polygon, total_pop, exposed_pop, non_exposed_pop, accuracy) AS(
SELECT id_polygon, COUNT(*), sum(is_interface::integer), COUNT(*) - sum(is_interface::integer), trunc((sum(is_interface::integer)::decimal/COUNT(*)), 3)
FROM interface_clusters_eval
GROUP BY 1)
SELECT a.id_polygon, coalesce(b.total_pop, 0), coalesce(b.exposed_pop, 0), coalesce(b.non_exposed_pop,0), coalesce(b.accuracy,0), CASE WHEN b.exposed_pop>=1 THEN TRUE ELSE FALSE END, a.geom
FROM wui.interface_polygons a LEFT OUTER JOIN summary b ON a.id_polygon=b.id_polygon
WHERE a.prevalent_exposure=3
);