CREATE TABLE lidar (
id serial primary key,
pa pcpatch(1),
h25 smallint not null
) PARTITION BY LIST (h25);

