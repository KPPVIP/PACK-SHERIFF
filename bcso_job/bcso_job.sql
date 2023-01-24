INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_bcso', 'bcso', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_bcso', 'bcso', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_bcso', 'bcso', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('bcso', 'Bcso')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('bcso',0,'recruit','Recrue',20,'{}','{}'),
	('bcso',1,'officer','Officier',40,'{}','{}'),
	('bcso',2,'sergeant','Sergent',60,'{}','{}'),
	('bcso',3,'lieutenant','Lieutenant',85,'{}','{}'),
	('bcso',4,'boss','Commandant',100,'{}','{}')
;