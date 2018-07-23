CREATE TABLE wui.config (fuel_cover_ids smallint[]);
COMMENT ON TABLE wui.config IS 'Table for configuration variables.';
COMMENT ON COLUMN config.fuel_cover_ids IS 'List of coverage IDs for fuel.';

CREATE MATERIALIZED VIEW wui.fuel
AS SELECT id_polygon, id_coberturas AS category, superf_por AS rel_area, superf_ha AS ha
FROM t_valores
WHERE array[id_coberturas] <@ (SELECT fuel_cover_ids FROM wui.config LIMIT 1);
COMMENT ON MATERIALIZED VIEW wui.fuel
IS 'Materialized view for fuel observations.';

CREATE index ON wui.fuel using btree (category);
CREATE index ON wui.fuel using btree (ha);
CREATE index ON wui.fuel using btree (id_polygon);
CREATE index ON wui.fuel using btree (rel_area);
							   
ALTER TABLE wui.config
ADD COLUMN residential_attr_ids smallint[];
 
CREATE MATERIALIZED VIEW wui.residential AS
SELECT id_polygon, btrim(atributos)::smallint AS category, superf_por AS rel_area, superf_ha AS ha
FROM t_valores
WHERE length(btrim(atributos))=2 AND array[btrim(atributos)::smallint] <@ (SELECT residential_attr_ids FROM wui.config LIMIT 1);
COMMENT ON MATERIALIZED VIEW wui.residential IS 'Materialized view for residential observations.';

CREATE index ON wui.residential using btree (category);
CREATE index ON wui.residential using btree (ha);
CREATE index ON wui.residential using btree (id_polygon);
CREATE index ON wui.residential using btree (rel_area);

CREATE VIEW wui.intermix AS
WITH a AS (
	SELECT id_polygon, category AS pop_type, rel_area AS pop_rel_area, ha AS pop_ha,
	sum(rel_area) OVER (PARTITION BY id_polygon) AS accum_pop_rel_area,
	sum(ha) OVER (PARTITION BY id_polygon) AS accum_pop_ha
	FROM wui.residential
), b AS (
	SELECT id_polygon, category AS fuel_type, rel_area AS fuel_rel_area, ha AS fuel_ha,
	sum(rel_area) OVER (PARTITION BY id_polygon) AS accum_fuel_rel_area,
	sum(ha) OVER (PARTITION BY id_polygon) AS accum_fuel_ha
	FROM wui.fuel
)
SELECT * FROM a NATURAL JOIN b WHERE accum_fuel_rel_area >= (SELECT intermix_min_fuel_area FROM wui.config LIMIT 1);

ALTER TABLE wui.config
ADD COLUMN intermix_min_fuel_area double precision;

CREATE VIEW wui.intermix_polygons AS
WITH a AS (
	SELECT id_polygon, sum(rel_area) AS accum_pop_rel_area, sum(ha) AS accum_pop_ha
	FROM wui.residential
	GROUP BY id_polygon
), b AS (
	SELECT id_polygon, sum(rel_area) AS accum_fuel_rel_area, sum(ha) AS accum_fuel_ha
	FROM wui.fuel
	GROUP BY id_polygon
), c AS (
	SELECT * FROM a NATURAL JOIN b
)
SELECT c.*, p.geom FROM c NATURAL JOIN t_poli_geo AS p
WHERE accum_fuel_rel_area >= (SELECT intermix_min_fuel_area FROM wui.config LIMIT 1);

ALTER TABLE wui.config
ADD COLUMN exposure_distance1 double precision,
ADD COLUMN exposure_distance2 double precision,
ADD COLUMN exposure_distance3 double precision;

INSERT INTO wui.config
VALUES ('{312,313,316,320}'::smallint[],'{21,22,23,24}'::smallint[],50,10,30,100);

CREATE MATERIALIZED VIEW wui.fuelpolygons AS
SELECT p.id_polygon, (p.geom)::geography AS geom,
st_setsrid(st_buffer((p.geom)::geography,(SELECT exposure_distance1 FROM wui.config LIMIT 1),2),4258) AS exposure1,
st_setsrid(st_buffer((p.geom)::geography,(SELECT exposure_distance2 FROM wui.config LIMIT 1),2),4258) AS exposure2,
st_setsrid(st_buffer((p.geom)::geography,(SELECT exposure_distance3 FROM wui.config LIMIT 1),2),4258) AS exposure3,
f.accum_fuel_area
FROM t_poli_geo AS p 
	NATURAL JOIN
		(SELECT fuel.id_polygon, sum(fuel.rel_area) AS accum_fuel_area
		 FROM wui.fuel
		 GROUP BY fuel.id_polygon) AS f;