# Tina

A tool to restore from Glacier into S3 over time in chunks, in order
to keep control of costs.

## Usage

What you need:

* The `total-storage` number, which is the amount of data stored in
  Glacier, in bytes. You can find a good enough estimate for this
  number by looking at the "Amazon Simple Storage Service
  EU-TimedStorage-GlacierByteHrs" line item on your bill for last
  month ("Amazon Simple Storage Service TimedStorage-GlacierByteHrs"
  for US regions).
* A `PREFIX_FILE` with lines on the format `s3://<BUCKET>/<PREFIX>` with
  all the prefixes you want to restore

An example of how this tool can be used follows.

Caroline stores 227 TiB of data in Glacier, which is 249589139505152
bytes. She wants to restore all photos from June 2014 from the bucket
`my-photos` and all her horror movies starting with the letter A and B
from `my-movies`. She prepares a file called `my-restore.txt` with the
following contents:

    s3://my-photos/2014/06/
    s3://my-movies/horror/A
    s3://my-movies/horror/B

She can now run tina like this;

    $ tina --total-storage=249589139505152 --duration=20h --keep-days=14 my-restore.txt

This will instruct tina to prepare a restore over __20 hours__ for all
objects matching the prefixes in `my-restore.txt` and keep the objects
on S3 for __14 days__. Using the monthly storage amount, tina can
estimate a price for the restore.

After printing information about the restore and an estimated price,
tina will ask Caroline whether to proceed.

Please note that tina is a long running process, which means it is a
good idea to run it under `screen` or `tmux`, and on a machine that is
constantly connected, e.g. an EC2 instance.

## Notes

* The estimated cost does not include the cost for the restore
  requests or the temporary storage on S3.
* The estimated cost is based on the assumption that no other restores
  are running in parallel, since that would incur a higher peak
  restore rate and consequently a higher cost.
* The parameter for specifying the number of days to keep objects on
  S3 is passed directly to the restore request. This means that
  objects restored in one of the first chunks may expire sooner from
  S3 than objects restored in one of the last chunks.

## Future improvements

* Speed up initial object listing by parallelizing requests
* Implement a mode where tina figures out the required restore time to
  restore given a specific budget (that might be $0)
* Implement resume and failure handling. Currently, if tina fails (for
  example due to a restore request failing) the prefix file would have
  to be updated manually in order to resume at the same place later.
* Use a first-fit algorithm to spread objects into chunks, instead of
  the current naïve ordered chunking
