set serveroutput on;
set timing on;
DECLARE
  ind NUMBER;              -- Loop index
  h1 NUMBER;               -- Data Pump job handler
  percent_done NUMBER;     -- Percentage of job complete
  job_state VARCHAR2(30);  -- To keep track of job state
  le ku$_LogEntry;         -- For WIP and error messages
  js ku$_JobStatus;        -- The job status from get_status
  jd ku$_JobDesc;          -- The job description from get_status
  sts ku$_Status;          -- The status object returned by get_status
BEGIN
  h1 := DBMS_DATAPUMP.OPEN('IMPORT','FULL',NULL,'EXAMPLE1');
  DBMS_DATAPUMP.ADD_FILE(h1,'<HR01.DMP>','DATA_PUMP_DIR');
  DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_SCHEMA','<HR>','<HR>');
  DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_TABLESPACE','<EXAMPLE>','<USERS>');
  DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','REPLACE');
  DBMS_DATAPUMP.START_JOB(h1);

  percent_done := 0;
  job_state := 'UNDEFINED';
  while (job_state != 'COMPLETED') and (job_state != 'STOPPED') loop
    dbms_datapump.get_status(h1,
           dbms_datapump.ku$_status_job_error +
           dbms_datapump.ku$_status_job_status +
           dbms_datapump.ku$_status_wip,-1,job_state,sts);
    js := sts.job_status;

 -- If the percentage done changed, display the new value.

      if js.percent_done != percent_done
    then
      dbms_output.put_line('*** Job percent done = ' ||
                           to_char(js.percent_done));
      percent_done := js.percent_done;
    end if;

 -- If any work-in-progress (WIP) or Error messages were received for the job,
-- display them.

        if (bitand(sts.mask,dbms_datapump.ku$_status_wip) != 0)
    then
      le := sts.wip;
    else
      if (bitand(sts.mask,dbms_datapump.ku$_status_job_error) != 0)
      then
        le := sts.error;
      else
        le := null;
      end if;
    end if;
    if le is not null
    then
      ind := le.FIRST;
      while ind is not null loop
        dbms_output.put_line(le(ind).LogText);
        ind := le.NEXT(ind);
      end loop;
    end if;
  end loop;

 -- Indicate that the job finished and gracefully detach from it. 

   dbms_output.put_line('Job has completed');
  dbms_output.put_line('Final job state = ' || job_state);
  dbms_datapump.detach(h1);
END;
/
