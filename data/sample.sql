BEGIN;

insert into locations(label) values
  ('site'),
  ('console'),
  ('call');

insert into partners(label, abbr) values
  ('belgian user support and operations centre', 'busoc'),
  ('space applications services', 'sas'),
  ('european space agency', 'esa'),
  ('royal belgian institute for space aeronomy', 'bisa');

insert into projects(label, dtstart, dtend, parent) values
  ('solar', '2008-02-15T00:00:00Z', '2017-02-16T00:00:002', null),
  ('asim', '2016-03-01T00:00:00Z', '2019-03-01T00:00:002', null),
  ('thor', '2016-09-01T00:00:00Z', '2016-09-10T00:00:002', null),
  ('fsl', '2014-06-12T00:00:00Z', '2019-06-12T00:00:002', null),
  ('geoflow', '2015-01-01T00:00:00Z', '2017-03-01T00:00:00Z', 4),
  ('smd', '2018-06-01T00:00:00Z', '2018-06-15T00:00:00Z', 4),
  ('foam-c', '2018-06-01T00:00:00Z', '2018-06-15T00:00:00Z', 4),
  ('ruby', '2018-10-01T00:00:00Z', '2018-10-15T00:00:00Z', 4);

insert into profiles(firstname, lastname, initial, email, phone, partner) values
  ('nicolas', 'brun', 'nbr', 'nicolas.brun@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('karim', 'litefti', 'kli', 'karim.litefti@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('dirk', 'pauwels', 'dpa', 'dirk.pauwels@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('loick', 'marcourt', 'lma', 'loick.marcourt@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('andre', 'somerhausen', 'aso', 'andre.somerhausen@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('claudio', 'queirolo', 'cqu', 'claudio.queirolo@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('anuschka', 'helderweirt', 'ahe', 'anuschka.helderweirt@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('sven', 'de ridder', 'sdr', 'sven.deridder@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('etienne', 'haumont', 'eha', 'etienne.haumont@busoc.be', '000/00.00.00', (select pk from partners where abbr='busoc')),
  ('carla', 'jacobs', 'cja', 'carla.jacobs@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('julien', 'dufey', 'jdu', 'julien.dufey@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('lode', 'pieters', 'lpi', 'lode.pieters@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('saliha', 'klai', 'skl', 'saliha.klai@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('koen', 'struyven', 'kst', 'koen.struyven@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('geraldine', 'marien', 'gma', 'geraldine.marien@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('alexander', 'karl', 'aka', 'alexander.karl@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('kevin', 'voet', 'kvo', 'kevin.voet@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('denis', 'vanhoof', 'dvh', 'denis.vanhoof@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas')),
  ('alejandro', 'diaz', 'adi', 'alejandro.diaz@busoc.be', '000/00.00.00', (select pk from partners where abbr='sas'));

insert into jobs(label, abbr) values
  ('developer', 'dev'),
  ('ground controller', 'gc'),
  ('operator', 'ops'),
  ('quality manager', 'paqa');

insert into positions(profile, job) values
  ((select pk from profiles where initial='nbr'), (select pk from jobs where abbr='dev')),
  ((select pk from profiles where initial='nbr'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='kli'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='dpa'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='lma'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='aso'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='adi'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='jdu'), (select pk from jobs where abbr='gc')),
  ((select pk from profiles where initial='cqu'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='ahe'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='sdr'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='kst'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='cja'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='lpi'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='jdu'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='kvo'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='gma'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='aka'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='dvh'), (select pk from jobs where abbr='ops')),
  ((select pk from profiles where initial='eha'), (select pk from jobs where abbr='paqa'));

insert into resources(project, job, count) values
  ((select pk from projects where label='asim'), (select pk from jobs where abbr='ops'), 4),
  ((select pk from projects where label='asim'), (select pk from jobs where abbr='dev'), 1),
  ((select pk from projects where label='asim'), (select pk from jobs where abbr='gc'), 2),
  ((select pk from projects where label='fsl'), (select pk from jobs where abbr='ops'), 6),
  ((select pk from projects where label='fsl'), (select pk from jobs where abbr='gc'), 3),
  ((select pk from projects where label='fsl'), (select pk from jobs where abbr='dev'), 2);

insert into vassignments(position, profile, project) values
  ('dev', 'nbr', 'asim'),
  ('gc', 'nbr', 'asim'),
  ('gc', 'jdu', 'asim'),
  ('gc', 'kli', 'asim'),
  ('gc', 'dpa', 'asim'),
  ('gc', 'adi', 'asim'),
  ('ops', 'jdu', 'asim'),
  ('ops', 'sdr', 'asim'),
  ('ops', 'cja', 'asim'),
  ('ops', 'ahe', 'asim'),
  ('dev', 'nbr', 'fsl'),
  ('gc', 'nbr', 'fsl'),
  ('gc', 'adi', 'fsl'),
  ('gc', 'aso', 'fsl'),
  ('ops', 'dvh', 'fsl'),
  ('ops', 'aka', 'fsl'),
  ('ops', 'lpi', 'fsl'),
  ('ops', 'kst', 'fsl');

insert into vshifts(position, profile, project, location, dtstart, dtend) values
    ('gc', 'jdu', 'asim', 'site', '2018-03-18T09:00:00Z', '2018-03-18T17:00:00Z'),
    ('dev', 'nbr', 'asim', 'site', '2018-03-18T09:00:00Z', '2018-03-18T17:00:00Z'),
    ('dev', 'nbr', 'asim', 'site', '2018-03-19T09:00:00Z', '2018-03-19T17:00:00Z'),
    ('dev', 'nbr', 'asim', 'site', '2018-03-20T09:00:00Z', '2018-03-20T17:00:00Z'),
    ('ops', 'cja', 'asim', 'console', '2018-03-18T09:00:00Z', '2018-03-18T17:00:00Z'),
    ('ops', 'cja', 'asim', 'console', '2018-03-19T09:00:00Z', '2018-03-19T17:00:00Z'),
    ('ops', 'cja', 'asim', 'console', '2018-03-20T09:00:00Z', '2018-03-20T17:00:00Z'),
    ('gc', 'adi', 'fsl', 'call', '2018-01-02T17:00:00Z', '2018-01-03T09:00:00Z'),
    ('dev', 'nbr', 'fsl', 'site', '2018-01-02T07:40:00Z', '2018-01-02T15:40:00Z'),
    ('dev', 'nbr', 'fsl', 'site', '2018-01-03T07:40:00Z', '2018-01-03T15:40:00Z'),
    ('dev', 'nbr', 'fsl', 'site', '2018-01-04T07:40:00Z', '2018-01-04T15:40:00Z'),
    ('dev', 'nbr', 'fsl', 'site', '2018-01-05T07:40:00Z', '2018-01-05T15:40:00Z'),
    ('gc', 'adi', 'fsl', 'site', '2018-01-02T09:00:00Z', '2018-01-02T17:00:00Z'),
    ('gc', 'adi', 'fsl', 'site', '2018-01-03T09:00:00Z', '2018-01-03T17:00:00Z'),
    ('gc', 'adi', 'fsl', 'site', '2018-01-04T09:00:00Z', '2018-01-04T17:00:00Z'),
    ('gc', 'adi', 'fsl', 'site', '2018-01-05T09:00:00Z', '2018-01-05T17:00:00Z'),
    ('gc', 'aso', 'fsl', 'site', '2018-01-02T09:00:00Z', '2018-01-02T17:00:00Z'),
    ('gc', 'aso', 'fsl', 'site', '2018-01-03T09:00:00Z', '2018-01-03T17:00:00Z'),
    ('gc', 'aso', 'fsl', 'site', '2018-01-04T09:00:00Z', '2018-01-04T17:00:00Z'),
    ('gc', 'aso', 'fsl', 'site', '2018-01-05T09:00:00Z', '2018-01-05T17:00:00Z');

COMMIT;
