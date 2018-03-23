use strict;
use warnings;

use utf8;

use Selenium::Chrome;
use Try::Tiny;

$|=1;

my $savedata;
open(my $fh, "<", "savedata.txt") or die $!;
while ( defined(my $l = <$fh>) ) {
    chomp $l;
    if ( $l ne '' ) {
        $savedata = $l;
    }
}
close $fh;

my $sel = Selenium::Chrome->new();
$sel->get('http://orteil.dashnet.org/cookieclicker/');
$sel->execute_script("return window.localStorage.setItem('CookieClickerGame', '$savedata')");
while (1) {
    last if ( $sel->execute_script("return window.Game.ready;") );
}
$sel->execute_script("window.Game.LoadSave();setInterval(window.Game.ClickCookie,20);window.Game.storeBulkButton(4)");
$sel->execute_script("setInterval(()=>{window.Game.shimmers.forEach((shimmer) => shimmer.pop());window.Game.CloseNotes();window.Game.autoclickerDetected=0},500)");

my $locator_golden_cookie = '//div[@class="shimmer"]';
my $elem_big_cookie = $sel->find_element('//div[@id="bigCookie"]');
my $locator_export = '//a[text()="Export save"]';
my $tm = time();
my $shouldUpgrade = 1;

while ( 1 ) {
    try {
        if ( $tm + 600 < time() ) {
            $savedata = $sel->execute_script("return window.Game.WriteSave() || window.localStorage.getItem('CookieClickerGame')");
            open my $fh, ">>", "savedata.txt" or die $!;
            print $fh "$savedata\n";
            close $fh;
            $tm = time();
            my ($sec, $min, $hour) = localtime($tm);
            printf("\nsaved(%02d:%02d:%02d)", $hour, $min, $sec);
        }
        &buy_upgrade() if ( $shouldUpgrade );
        &buy_product();
        &click_grimoire();

        if ( $sel->execute_script("return window.Game.elderWrath") ) {
            &explode_wrinklers();
        }
        print ".";
    } catch {
        print "ERROR(while): $_";
    };
}

exit;

sub buy_upgrade {
    my $locator = '//div[@id="upgrades"]/div[@class="crate upgrade enabled"][1]';
    &click($locator, "upgrade");
    $shouldUpgrade = 0 if ( !scalar($sel->find_elements('//div[@id="upgrades"]/div[@class="crate upgrade"]')) );
}

sub buy_product {
    my $locator = '//div[@id="products"]/div[@class="product unlocked enabled"][last()]';
    &click($locator, "product");
}

sub click_grimoire {
    my $locator = '//div[@id="grimoireSpell1" and contains(@class, "ready")]';
    &click($locator, "grimoireSpell1");
}

sub explode_wrinklers {
    $sel->execute_script("window.Game.SaveWrinklers().number < window.Game.getWrinklersMax() || window.Game.CollectWrinklers()");
}

sub click {
    my $target = shift;
    my $target_name = shift;
    my $cnt = 0;
    while (1) {
        my @elems;
        my $loop;
        try {
            @elems = $sel->find_elements($target);
        } catch {
            @elems = ();
        };
        my $target_num = @elems;

        last if ( $target_num < 1 );
        print "$target_num";
        if ($target_num > 1) {
            print "\ntry to click $target_num targets.";
        }

        $loop = 1;
        for my $elem (@elems) {
            try {
                $elem->click();
                ++$cnt;
            } catch {
                $loop = 0;
            };
            last if (!$loop);
        }
        print "+";
    }
    if ( $cnt && $target_name ) {
        print "\nclick $target_name(x$cnt)";
    }
    return $cnt;
}
