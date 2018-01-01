create or replace view vprofiles(pk, firstname, lastname, initial, email, phone, partner, positions, enabled) as
  with ps(profile, positions) as (
    select
      p.profile,
      array_agg(lower(j.abbr))
    from
      positions p
      join jobs j on p.job=j.pk
    group by
      p.profile
  )
  select
    p.pk,
    p.firstname,
    p.lastname,
    p.initial,
    p.email,
    p.phone,
    coalesce(a.abbr, ''),
    coalesce(s.positions, '{}'::varchar[]),
    true
  from profiles p
    left outer join partners a on p.partner=a.pk
    left outer join ps s on p.pk=s.profile;

create or replace view vpartners(pk, label, abbr, profiles) as
  with ps(partner, profiles) as (
    select
      p.partner,
      array_agg(p.initial)
    from
      profiles p
    group by p.partner
  )
  select
    p.pk,
    p.label,
    p.abbr,
    coalesce(s.profiles, '{}'::text[])
  from
    partners p
    left outer join ps s on p.pk=s.partner;

create or replace view vprojects(pk, label, dtstart, dtend, manager, done) as
  select
    p.pk,
    p.label,
    p.dtstart,
    p.dtend,
    coalesce(f.initial, ''),
    case
      when p.dtstart is null and p.dtend is null then false
      else p.dtend <= now()
    end
  from
    projects p
    left outer join profiles f on p.manager=f.pk;

create or replace view vpositions(pk, profile, position, ratio, assignable) as
  select
    s.pk,
    p.initial,
    j.abbr,
    s.ratio,
    s.dtend is null and j.assignable
  from
    positions s
    join profiles p on s.profile=p.pk
    join jobs j on s.job=j.pk;

create trigger assign instead of insert on vpositions for each row execute procedure assignPosition();
create trigger unassign instead of delete on vpositions for each row execute procedure unassignPosition();

create or replace view vjobs(pk, label, abbr, manager, profiles, assignable) as
  with js(pk, label, abbr, manager, assignable) as (
    select
      j.pk,
      j.label,
      j.abbr,
      coalesce(p.initial, ''),
      j.assignable
    from
      jobs j
      left outer join profiles p on j.manager=p.pk
  ), ps(job, profiles) as (
    select
      j.job,
      array_agg(p.initial)
    from
      profiles p
      join positions j on p.pk=j.profile
    group by
      j.job
  )
  select
    j.pk,
    j.label,
    j.abbr,
    j.manager,
    coalesce(p.profiles, '{}'::text[]),
    j.assignable
  from
    js j
    left outer join ps p on p.job=j.pk;

create or replace view vassignments(pk, profile, position, project, ratio, assignable) as
  select
    a.pk,
    p.profile,
    p.position,
    j.label,
    a.ratio,
    a.dtend is null and p.assignable
  from
    assignments a
    join projects j on a.project=j.pk
    join vpositions p on a.position=p.pk;

create trigger assign instead of insert on vassignments for each row execute procedure assignProject();
create trigger unassign instead of delete on vassignments for each row execute procedure unassignProject();

create or replace view vresources(position, project, expected, current, fulfilled) as
  with cs(project, position, count) as (
    select
      a.project,
      p.job,
      count(p.job)::int
    from
      positions p
      join assignments a on p.pk=a.position
    group by
      a.project,
      p.job
  )
  select
    j.abbr,
    p.label,
    r.count,
    cs.count,
    cs.count>=r.count
  from
    projects p
    join resources r on p.pk=r.project
    join jobs j on j.pk=r.job
    join cs on (cs.project=p.pk and cs.position=j.pk);

create or replace view vshifts(pk, profile, position, project, location, dtstart, dtend) as
  select
    s.pk,
    a.profile,
    a.position,
    a.project,
    l.label,
    s.dtstart,
    s.dtend
  from
    shifts s
    join vassignments a on s.assignment=a.pk
    join locations l on s.location=l.pk;

create trigger assign instead of insert on vshifts for each row execute procedure assignShift();

create or replace view vstats(profile, position, project, total, duration) as
  select
    profile,
    position,
    project,
    count(pk),
    extract(epoch from sum(dtend-dtstart))
  from
    vshifts
  group by profile, position, project;
