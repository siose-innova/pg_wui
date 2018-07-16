CREATE TABLE wui.config (fuel_cover_ids smallint[]);
COMMENT ON TABLE wui.config IS 'Table for configuration variables.';
COMMENT ON COLUMN config.fuel_cover_ids IS 'List of coverage IDs for fuel.';

INSERT INTO wui.config VALUES ('{312,313,316,320}'::smallint[]);

CREATE materialized view wui.fuel
AS SELECT id_polygon, id_coberturas AS category, superf_por AS rel_area, superf_ha AS ha
FROM t_valores
WHERE array[id_coberturas] <@ (SELECT fuel_cover_ids FROM wui.config);
COMMENT ON materialized view wui.fuel
IS 'Materialized view for fuel observations.';