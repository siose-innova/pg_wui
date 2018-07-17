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
 
INSERT INTO wui.config
VALUES ('{312,313,316,320}'::smallint[],'{21,22,23,24}'::smallint[]);
		
CREATE MATERIALIZED VIEW wui.residential AS
SELECT id_polygon, btrim(atributos)::smallint AS category, superf_por AS rel_area, superf_ha AS ha
FROM t_valores
WHERE length(btrim(atributos))=2 AND array[btrim(atributos)::smallint] <@ (SELECT residential_attr_ids FROM wui.config LIMIT 1);
COMMENT ON MATERIALIZED VIEW wui.residential IS 'Materialized view for residential observations.';

CREATE index ON wui.residential using btree (category);
CREATE index ON wui.residential using btree (ha);
CREATE index ON wui.residential using btree (id_polygon);
CREATE index ON wui.residential using btree (rel_area);