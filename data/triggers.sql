create or replace function assignPosition() returns trigger as $assign_position$
  declare
    profile int;
    job int;
  begin
    select pk into profile from profiles where initial=NEW.profile;
    select pk into job from jobs where abbr=NEW.position;

    if NEW.ratio is null then
      NEW.ratio = 1.0;
    end if;

    insert into positions(profile, job, ratio) values(profile, job, NEW.ratio) returning pk into NEW.pk;

    return NEW;
  end;
$assign_position$ language plpgsql;

create or replace function unassignPosition() returns trigger as $unsassign_position$
  declare
    jid int;
    pid int;
    bid int;
  begin
    select pk into pid from profiles where initial=OLD.profile;
    select pk into bid from jobs where abbr=OLD.position;
    update positions set dtend=current_timestamp where profile=pid and job=bid returning pk into jid;
    update assignments set dtend=current_timestamp where position=jid and dtend is null;

    return OLD;
  end;
$unsassign_position$ language plpgsql;

create or replace function assignProject() returns trigger as $assign_project$
  declare
    pid int;
    jid int;
    position int;
    project int;
  begin
    select pk into pid from profiles where initial=NEW.profile;
    select pk into jid from jobs where abbr=NEW.position;
    select p.pk into position from positions p where p.profile=pid and p.job=jid;
    select p.pk into project from projects p where p.label=NEW.project;

    if NEW.ratio is null then
      NEW.ratio = 1.0;
    end if;

    insert into assignments(position, project, ratio) values(position, project, NEW.ratio) returning pk into NEW.pk;

    return NEW;
  end;
$assign_project$ language plpgsql;

create or replace function unassignProject() returns trigger as $$
  declare
    pid int;
    jid int;
  begin
    select pk into pid from vpositions where position=OLD.position and profile=OLD.profile;
    if pid is null then
      raise exception 'position % not assigned to %', OLD.position, OLD.profile;
    end if;
    
    select pk into jid from projects where label=OLD.project;
    if jid is null then
      raise exception 'project % not found', OLD.project;
    end if;

    update assignments set dtend=current_timestamp where position=pid and project=jid and dtend is null;

    return OLD;
  end;
$$ language plpgsql;

create or replace function assignShift() returns trigger as $assign_shift$
  declare
    aid int;
    lid int;
  begin
    select
      v.pk into aid
    from
      vassignments v
      join assignments a on a.pk=v.pk
    where
      v.position=NEW.position
      and v.profile=NEW.profile
      and v.project=NEW.project
      and v.assignable;
    select pk into lid from locations where label=NEW.location;

    insert into shifts(assignment, location, dtstart, dtend) values(aid, lid, NEW.dtstart, NEW.dtend) returning pk into NEW.pk;

    return NEW;
  end;
$assign_shift$ language plpgsql;
