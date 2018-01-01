drop table if exists partners cascade;
drop table if exists locations cascade;
drop table if exists profiles cascade;
drop table if exists availabilities cascade;
drop table if exists unavailabilities cascade;
drop table if exists positions cascade;
drop table if exists jobs cascade;
drop table if exists allowances cascade;
drop table if exists projects cascade;
drop table if exists resources cascade;
drop table if exists assignments cascade;
drop table if exists shifts cascade;
drop table if exists schemes cascade;
drop table if exists periods cascade;
drop table if exists schedules cascade;

create table partners (
  pk serial not null,
  label varchar(128) not null check (length(label) > 0),
  abbr varchar(8) not null check (abbr ~* '^[a-z]{2,}$'),
  primary key(pk),
  unique(abbr)
);

create table locations (
  pk serial not null,
  label varchar(256) not null check (length(label) > 0),
  primary key(pk),
  unique(label)
);

create table profiles (
    pk serial not null,
    firstname varchar(64) not null check (length(firstname) > 0),
    lastname varchar(64) not null check (length(lastname) > 0),
    initial varchar(4) not null check (initial ~* '^[a-z]{2,}$'),
    email varchar(128) not null check (length(email) > 0),
    phone varchar(32) not null check (length(phone) > 0),
    partner int,
    primary key(pk),
    foreign key(partner) references partners(pk),
    unique(email),
    unique(initial)
);

create table availabilities (
  pk serial not null,
  dtstart timestamp not null,
  dtend timestamp not null,
  profile int not null,
  primary key(pk),
  foreign key(profile) references profiles(pk)
);

create table unavailabilities (
  like availabilities including all,
  holiday bool default false not null
);

create table jobs (
  pk serial not null,
  label varchar(128) not null check(length(label) > 0),
  abbr varchar(8) not null check (abbr ~* '^[a-z]{2,}$'),
  assignable boolean default true not null,
  manager int,
  primary key(pk),
  foreign key(manager) references profiles(pk),
  unique(abbr)
);

create table allowances (
  pk serial not null,
  job int not null,
  partner int not null,
  daily int not null,
  monthly int not null,
  night bool default false not null,
  weekend bool default false not null,
  assignable boolean default true not null,
  primary key(pk),
  foreign key(partner) references partners(pk),
  foreign key(job) references jobs(pk)
);

create table positions (
  pk serial not null,
  profile int not null,
  job int not null,
  dtstart timestamp default current_timestamp not null,
  dtend timestamp,
  ratio real not null default 1.0 check (ratio between 0.0 and 1.0),
  primary key(pk),
  foreign key(profile) references profiles(pk),
  foreign key(job) references jobs(pk),
  unique(profile, job)
);

create table projects (
  pk serial not null,
  label varchar(128) not null check (length(label) > 0),
  dtstart timestamp,
  dtend timestamp,
  manager int,
  parent int,
  primary key(pk),
  foreign key(manager) references profiles(pk),
  foreign key(parent) references projects(pk),
  unique(label)
);

create table resources (
  project int not null,
  job int not null,
  count int default 0 not null,
  primary key(project, job),
  foreign key(project) references projects(pk),
  foreign key(job) references jobs(pk)
);

create table assignments (
  pk serial not null,
  position int not null,
  project int not null,
  dtstart timestamp default current_timestamp not null,
  dtend timestamp,
  ratio real not null default 1.0 check (ratio between 0.0 and 1.0),
  primary key(pk),
  foreign key(position) references positions(pk),
  foreign key(project) references projects(pk),
  unique(position, project)
);

create table shifts (
  pk serial not null,
  assignment int not null,
  location int not null,
  dtstart timestamp not null,
  dtend timestamp not null,
  primary key(pk),
  foreign key(assignment) references assignments(pk),
  foreign key(location) references locations(pk)
);

create table schemes (
  pk serial not null,
  label varchar(256) not null,
  project int not null,
  job int not null,
  primary key (pk),
  foreign key(project) references projects(pk),
  foreign key(job) references jobs(pk)
);

create table periods (
  pk serial not null,
  dtstart time not null,
  dtend time not null,
  label varchar(256) not null,
  primary key(pk)
);

create table schedules (
  location int not null,
  period int not null,
  scheme int not null,
  primary key(location, period, scheme),
  foreign key(location) references locations(pk),
  foreign key(period) references periods(pk),
  foreign key(scheme) references schemes(pk)
);
