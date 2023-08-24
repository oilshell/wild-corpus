#!/bin/bash
if [[ -n $1 && "$1" = overwrite ]]; then
    OVERW="true"
fi

SSHCOMMON="-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o VerifyHostKeyDNS=no"
SSHCMD="ssh $SSHCOMMON"
SCPCMD="scp $SSHCOMMON"

BOOT=`./cluster-whatsup.sh bcpc-bootstrap | grep 10`
if [[ ${BOOT} = "10.0.100.3" ]]; then
    echo "Bootstrap node is up..."
    if [[ ! -d ../output ]]; then
        mkdir ../output
    else
        echo "Output directory ../output exists."
        if [[ -f ../output/bins.tar.gz || -f ../output/cookbooks.tar.gz ]]; then
            if [[ -z "$OVERW" ]]; then
                echo "output files already exist, not overwiting..."
                exit 1
            else
                echo "overwriting specified, continuing."
            fi
        fi
    fi
    BNDO="sshpass -p ubuntu $SSHCMD -t ubuntu@10.0.100.3"

    # Collect all the non-BCPC cookbooks sub-dirs - this is somewhat
    # fragile. Ideally we'd find everything that looks like a cookbook
    # and then exlude BCPC ones. For now though we can collect
    # everything except our own cookbooks and a couple of files that
    # land here typically.

    # Even better would be to put 3rd-party cookbooks in a separate
    # directory entirely, but then we would have to feed that path
    # info back to knife
    echo "Collecting non-BCPC cookbooks..."
    $BNDO "cd chef-bcpc && tar --exclude=bcpc --exclude=bcpc-centos --exclude=chef-client.patch --exclude=${PWD}/README.md -cf ../cookbooks.tar cookbooks"

    # and now our built binaries. This is easier to do, except they
    # are buried deep down. Perhaps it would be better for the
    # build_bins.sh script to copy them somewhere else for safekeeping
    # after a successful run since it is working in that directory
    # already.
    echo "Collecting built binaries..."
    $BNDO "cd chef-bcpc/cookbooks/bcpc/files/default && tar -cf ../../../../../bins.tar bins"
    echo "Compressing files..."
    $BNDO "gzip cookbooks.tar bins.tar"
    sshpass -p ubuntu $SCPCMD ubuntu@10.0.100.3:/home/ubuntu/bins.tar.gz ../output
    sshpass -p ubuntu $SCPCMD ubuntu@10.0.100.3:/home/ubuntu/cookbooks.tar.gz ../output
    echo "Removing files from bootstrap node..."
    $BNDO "rm cookbooks.tar.gz bins.tar.gz"
    echo "Finished :"
    ls -l ../output
else
    echo "Fail."
fi
