## How to process big puzzle archive (like bwh.zip)

        rm -rf bwh-zips/ && mkdir bwh-zips
        ./scripts/90-split-archive.py -o bwh-zips/ --source bwh-2015.tgz bwh/
        ./scripts/18-convert2xd.py -o gxd/ bwh-zips/up.zip

## How to check receipts.tsv for dublicate values

### filter out duplicates based on InternalSource & Filename

        awk 'BEGIN {FS="\t"} {c[$5$6]++} {if (c[$5$6] == 1) print $0}' receipts.tsv

### number of receipts

        cat receipts.tsv | wc -l

### enumerate ExternalSources with amount of receipts

        cat receipts.tsv | cut -f 4 | sort | uniq -c | sort -n

### enumerate InternalSources with amount of receipts

        cat receipts.tsv | cut -f 5 | sort | uniq -c | sort -n

### print duplicate receipts based on InternalSource & Filename

        cat receipts.tsv | cut -f 5,6 | sort | uniq -d -c

### print dublicate receipts based on receiptid

        cat receipts.tsv | cut -f 1 | sort -n | uniq -c -d