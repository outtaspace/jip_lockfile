use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp;
use English qw(-no_match_vars);

use constant NEED_TMP_FILE => 1;

plan tests => 8;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::LockFile', '0.01';
    require_ok 'JIP::LockFile';

    diag(
        sprintf 'Testing JIP::LockFile %s, Perl %s, %s',
            $JIP::LockFile::VERSION,
            $OLD_PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'new()' => sub {
    plan tests => 7;

    eval { JIP::LockFile->new };
    like $EVAL_ERROR, qr{Mandatory \s argument \s "lock_file" \s is \s missing}x;

    eval { JIP::LockFile->new(lock_file => undef) };
    like $EVAL_ERROR, qr{Bad \s argument \s "lock_file"}x;

    eval { JIP::LockFile->new(lock_file => q{}) };
    like $EVAL_ERROR, qr{Bad \s argument \s "lock_file"}x;

    my $obj = init_obj();
    ok $obj, 'got instance of JIP::LockFile';

    isa_ok $obj, 'JIP::LockFile';

    can_ok $obj, qw(new get_lock_file lock try_lock unlock is_locked);

    is $obj->get_lock_file, $EXECUTABLE_NAME;
};

subtest 'not is_locked() at startup' => sub {
    plan tests => 1;

    cmp_ok init_obj()->is_locked, '==', 0;
};

subtest 'unlock on non-is_locked() changes nothing' => sub {
    plan tests => 2;

    is ref(init_obj()->unlock), 'JIP::LockFile';
    cmp_ok init_obj()->is_locked, '==', 0;
};

subtest 'lock()' => sub {
    plan tests => 4;

    my $obj = init_obj(NEED_TMP_FILE);

    is ref($obj->lock), 'JIP::LockFile';
    cmp_ok $obj->is_locked, '==', 1;

    # Re-locking changes nothing
    is ref($obj->lock), 'JIP::LockFile';
    cmp_ok $obj->is_locked, '==', 1;
};

subtest 'unlock()' => sub {
    plan tests => 3;

    my $obj = init_obj(NEED_TMP_FILE)->lock;

    ok -f $obj->get_lock_file;

    $obj->unlock;

    cmp_ok $obj->is_locked, '==', 0;
    ok not -f $obj->get_lock_file;
};

subtest 'unlocking on scope exit' => sub {
    plan tests => 1;

    my $lock_file;

    {
        my $obj = init_obj(NEED_TMP_FILE);
        $lock_file = $obj->get_lock_file;
        $obj->lock;
    }

    ok not -f $lock_file;
};

subtest 'Lock or raise an exception' => sub {
    my $obj       = init_obj(NEED_TMP_FILE)->lock;
    my $lock_file = $obj->get_lock_file;

    eval { JIP::LockFile->new(lock_file => $lock_file)->lock };
    like $EVAL_ERROR, qr{^Can't \s lock \s "$lock_file":}x;

    done_testing;
};

sub init_obj {
    my $need_tmp_file = shift;

    my $lock_file = $need_tmp_file ? File::Temp->new->filename : $EXECUTABLE_NAME;

    return JIP::LockFile->new(lock_file => $lock_file);
}

