#!/usr/local/bin/perl5
#####################################################################
#
# Webtrax          
$version = "v23";
#
# This script takes a web server's log file and attempts to report
# the activities of individual site visitors, including what pages
# they viewed and for how long (in mm:ss format). Because of things like
# disk caching, though, the script's output should not be taken too
# seriously.
#
# USAGE:
#  perl5 webtrax.pl [webtrax.rc] [log files...]
#
#  If a file name given on the command line has the suffix .rc it is
#    processed as a configuration file, containing lines of the form
#       $variable = "value";
#    and these settings override the defaults given below.
#  Other file names are those of log files.  They are processed in order.
#  With no arguments, webtrax looks for "webtrax.rc" and then 
#  processes the one file httpd_access.0.
#
# See http://www.multicians.org/thvv/tvvtools.html for more info.
#
################################################################
#use Devel::Peek;
# Based on the version by John Callender of 6 Oct 1995
# 10/10/95 THVV start time for visits, add table of entry times
# 12/06/95 THVV show bars for histogram
# 12/13/95 THVV count busy domains & toplevel domains
# 12/24/95 THVV count hits not visits for busy domains
# 12/24/95 THVV cumulative hits per page and tld
# 03/30/96 THVV improve parsing, don't die on referrer & browser
# 04/06/96 THVV improve formatting
# 04/24/96 THVV handle .class, distinguish .aol.com etc, report by browser
# 07/16/96 THVV v2 summarize serch engines and search terms.
# 09/11/96 THVV v3 better summaries, referrer report, catch MSIE
# 09/26/96 THVV v5 summary of hits and bytes per visit, new switch, .rc file
# 11/04/96 THVV v6 show visits/KB/hits for histograms
# 11/07/96 THVV v7 improve arg processing, handle logs w/o referrer better
# 11/11/96 THVV v8 know about head pages, robots, summary list; fix some bugs
# 11/15/96 THVV v8 avgs on summary, some analysis, more engines & load from .rc
# 11/20/96 THVV v8 handle bad logs better, other bug fixes
# 12/10/96 THVV v8 add general analysis and averages
# 12/20/96 THVV v8 add charts of hits by type and visits by source
# 12/23/96 THVV v8 add cumulative history on referrers, fix a bug
# 12/26/96 THVV v8 robot detector on browser, not site name; totals on histo
# 05/15/97 THVV v10 fix a zerodivide
# 06/15/97 THVV v10 rewrite the html output completely, add class report
# 07/21/97 THVV v11 fixes to accommodate MSIE, produce better HTML
# 10/01/97 THVV v12 add browser wars chart
# 10/08/97 THVV v12 striped the hour histogram by hit type
# 10/14/97 THVV v13 fix bug that reset ytd page hits
# 10/14/97 THVV v13 add indexer sessions; detect more engines; detect WebTV
# 01/10/98 THVV v14 fix bug, missing 1st summary line in text mode
# 01/10/98 THVV v14 max 32 char browser
# 02/15/98 THVV v15 color search args green, new referrers red; new report by retcode
# 02/15/98 THVV v15 preprocessing & search engines from Paul Schmidt (advo@best.com)
# 05/14/98 THVV v16 allow html-ssi and asp; use "my" not "local"
# 06/09/98 THVV v16 allow user to extend HTML types; allow report on .css files
# 06/09/98 THVV v16 color the biggest numbers in the summary red
# 06/09/98 THVV v16 Don't add visits to the detail list if they won't list a page
# 06/21/98 THVV v16 Fix the illegal referrer report to come out & make sense
# 06/21/98 THVV v16 New: default class from subdir from Paul Schmidt
# 06/26/98 THVV v17 Reorganized code; passed refs instead of typeglobs
# 08/25/98 THVV v17 added ink.yahoo.com; if provided, use html preamble and postamble
# 08/25/98 THVV v17 added META tag to keep robots from indexing or following
# 09/04/98 THVV v17 put in fix for browser pie chart
# 09/09/98 THVV v17 added navbar; corrected a few search engine detectors
# 12/01/98 THVV v18 if it has args and looks like a query, treat it as one
# 12/28/98 THVV v18 Add feature to print certain filenames in red if path matches
# 01/10/99 THVV v18 Fix to ensure that a .rc file is read; help file for each version
# 11/29/99 THVV v18 Add .swf and .pl to known file suffixes
# 11/29/99 THVV v18 Expand country TLD suffixes
# 03/21/00 THVV v18 more query recognizers; local queries
# 04/26/00 THVV v18 preprocessing of domain names; control hotlinking of filenames
# 05/04/00 THVV v18 allow out of sequence times; validity check size
# 11/10/00 THVV v18 add switch to suppress indexer sessions from details
# 03/30/01 THVV v18 optionally do reverse DNS lookup on numeric domains
# 04/05/01 THVV v18 Automatically handle zipped input files
# 07/31/01 THVV v19 Strip out userid from referrer
# 09/07/01 THVV v19 Better recog for browser, add to detail
# 11/05/01 THVV v19 Write details into a temp file and read it back.
# 11/05/01 THVV v19 Added hook of code for later pruning of cumreferrer.hit
# 11/23/01 THVV v19 Add a chart for platform wars.  Depressing.
# 12/02/01 THVV v19 Tightened escapeHtml to avoid printing bad chars.
# 12/04/01 THVV v19 Session that begins with robots.txt will be indexer.
# 04/05/02 THVV v20 Use CSS to float the DT, fix a few spacing glitches, use styles
# 08/14/02 THVV v20 Apply inred to filename report
# 09/17/02 THVV v20 Add dnscache fixes from Ned Batchelder (www.nedbatchelder.com)
# 09/17/02 THVV v20 Add rettype cmd from Ned Batchelder.
# 09/17/02 THVV v20 Add pre_url cmd from Ned Batchelder.
# 09/22/02 THVV v21 Fix "illegal referrer" check for trailing slash on domain name.
# 09/22/02 THVV v21 Improve "illegal referrer" report to show what file.
# 10/03/02 THVV v21 Use CSS to improve table appearance.
# 10/09/02 THVV v21 Make some string matches case insensitive.
# 10/16/02 THVV v21 Add a stylesheet option, make html report validate with 4.01.
# 04/04/03 THVV v21 Added PDF to downloads.
# 05/22/03 THVV v21 Tried dbmopen to try to reduce memory load.  Didn't work, took out.
# 06/01/03 THVV v21 Introduced Visit class to reduce memory load a little.
# 06/01/03 THVV v21 Added use strict to process_one_file.
# 06/01/03 THVV v21 Changed visit counting: a visit with no HTML pages is still a visit.
# 06/06/03 THVV v21 Added some undefs to try to reduce memory use, didn't help.
# 06/17/03 THVV v21 Added a stack to reuse Visit entries.
# 08/19/03 THVV v21 Compress strings of pluses in referrer.
# 10/18/03 THVV v21 Put count of files in filetype report headers.
# 10/18/03 THVV v21 Improved recognition of platforms.
# 11/14/03 THVV v21 Don't put PNG files in details.
# 05/25/04 THVV v21 Add flag to report PNGs.
# 05/25/04 THVV v21 Several fixes thanks to Simon Child (simon@srchild.com).
# 07/07/04 THVV v21 Fix the escaping of filenames in HTML mode.
# 08/04/04 THVV v21 Add optional TLD lookup using geoip (http://www.maxmind.com/app/geoip_country).
# 08/25/04 THVV v22 Accept pre-geoip'd data (see logextractor).  
# 08/25/04 THVV v22 Fix bug in numeric TLD recognition.
# 11/22/04 THVV v22 Add max_referrer_length, max_query_length, max_browser_length. 
# 11/23/04 THVV v22 Added report of visits with no HTML.
# 04/04/05 THVV v22 Add max_domain_length. 
# 04/04/05 THVV v22 Known indexer visits get separate css class, "indexer". (requested by Ben Eden)
# 04/09/05 THVV v22 Not an indexer if it has a query.
# 04/15/05 THVV v23 Generalize inred to filedisplay
# 05/07/05 THVV v23 Add min_details_sessioncount
# 05/07/05 THVV v23 Don't put .ico files in details
# 06/17/05 THVV v23 Add robotdomain.
# 07/07/05 THVV v23 Don't put search referrers in cumreferrer.hit.
# 12/18/05 THVV v23 Add javapie switch. (for Ben Eden)
# 12/18/05 THVV v23 Process percent escapes in extractquery. (for Ben Eden)
# 03/18/06 THVV v23 Fix handling of bad summary.txt
# 03/24/06 THVV v23 Add summary by transaction verb.
# 03/24/06 THVV v23 Better handling for Google images by default.
# 03/24/06 THVV v23 Fix bug in recognition of 304 transactions.
# 03/24/06 THVV v23 Fix query detector for google images.
# 03/25/06 THVV v23 Added debug switch and checking for bad commands, not in documentation.
# 03/25/06 THVV v23 Allow coloring of details by retcode, color 304s pink. No rcfile interface yet, edit the source.
# 04/10/06 THVV v23 Parameterize check on transaction verb
# 04/11/06 THVV v23 Handle escaped quote in quoted strings

# idea: allow "include" directive in the .rc file
# to do: move some utilities to modules
# to do: stripe other bars by file type
# to do: handle .js files differently? how bout .doc, .ppt, .xls?
# to do: change histogram to use descriptive letters, H=html etc
# to do: striped bars get funny when below 1 pixel resolution
# to do: use a tpt for html
# to do: make modular and interpret a report generator language
# to do: use SQL for data storage, generate reports as queries
# to do: (Ben Eden) Increased (or better customizable) length of entries in all bar reports
# to do: (Ben Eden) Make URLs in reports clickable
# to do: (Ben Eden) user time zone preference

################################################################
package Visit;
# This class is an attempt to shrink the amount of memory consumed,
# by replacing 14 hashes with one.  It also makes it more clear
# what is going on, I hope.
package Visit;
sub new {
    my $self = {};
    bless $self;
    return $self;
}

my $domain;			# what domain
my $times;			# time session started in seconds
my $hits;			# hits
my $size;			# bytes
my $visitclass;			# visit class
my $hittype;			# hit type
my $hourx;			# hour session started
my $browser;			# browser string
my $tld;			# toplevel domain
my $referrer;			# referrer string
my $query;			# query string
my $engine;			# search engine
my $pages;			# html pages
my $details;			# long detailed string

sub display {
    my $self = shift;
    print "Visit:$self->{domain}:$self->{times}:$self->{hits}:$self->{size}:$self->{visitclass}:$self->{hittype}:$self->{hourx}:$self->{browser}:$self->{tld}:$self->{referrer}:$self->{query}:$self->{engine}:$self->{pages}:$self->{details}\n";
}

package main;
################################################################
# Variables are named in the program with the following scheme.
# $year_ ... are "yearly" totals.  They reset when you delete cumtld.hit and cumpage.hit
# $month_... are "monthly" totals.  The summary report contains $month_days lines
# $day_... are "daily" totals, assuming that you run webtrax on 24 hours' logs at a time.

# Useful constants

@hittype_names=('search','search+hp','hp','link+hp','link','indexer','local','other');
$gifnames{'search'} = 'redpix.gif';
$gifnames{'search+hp'} = 'bluepix.gif';
$gifnames{'hp'} = 'greenpix.gif';
$gifnames{'link+hp'} = 'yellowpix.gif';
$gifnames{'link'} = 'purplepix.gif';
$gifnames{'indexer'} = 'orangepix.gif';
$gifnames{'local'} = 'pinkpix.gif';
$gifnames{'other'} = 'graypix.gif';

# If you generate HTML output, it hyperlinks some terms to the help.
$help_html = "http://www.multicians.org/thvv/webtrax-help$version.html";

$site_name = "Unconfigured Website, read $help_html for info"; # site name for the report title
$log_file = 'httpd_access.0';	# name of the input log file
$output_file = 'report.txt';	# name of the output file
$return_URL = 'index.html';	# URL to return from html report
$html = 0;		# mode of processing
$hbh = 10;		# height of HTML bar
$hbw = 8;			# scaling for HTML bar
$nhhw = 50;		# non-HTML histogram width in chars
$preamble = "";               # optional file name containing head of HTML report
$postamble = "";              # optional file name containing tail of HTML report
$detail_temp_file = "webtrax_detail_temp";
$stylesheet = "";		# name of external style sheet, blank for default
$max_referrer_length = 32;	# maximum length of referrer in report
$max_query_length = 32;	# maximum length of query in report
$max_browser_length = 32;	# maximum length of browser in report
$max_domain_length = 255;	# maximum length of domain in report, gets long for cable
$max_key_lth = 255;		# maximum length of keynames in histograms, to be overridden

# If you give $output_file an .html extension, the script
# will create an htmlized version of the report, setting permissions
# on it to 644 (world readable). In this case, the contents of the
# $return_URL variable (which can be either a full or partial URL) will be
# used to create a link from the report page back to the page on which
# you referenced it.

$mailto_address = '';		# mail address for mailed report
$mail_program = '/usr/sbin/Mail'; # location of your system's mail program

# Setting $mailto_address to one or more email addresses (separated
# by spaces within the double quotes) will cause the script to
# mail its output file to the given address(es). Leaving $mailto_address
# empty (or commenting out the whole line) turns off this feature.
# Be sure to put a backslash in front of the @ symbol, e.g.
# "jbc\@oimage.com".

$month_days = '31';		# number of script runs to summarize

# summary lines are printed at the beginning of the output file; between
# invocations of the script they are stored in the file summary.txt

$expire_time = '1800';		# elapsed time until "visit" ended

# The script needs a way to tell when it should stop looking for accesses
# from a particular domain, and write that domain's visit record to the
# "details" section. Hence the $expire_time, which has a default of
# 1800 seconds (30 minutes). Any longer than that between accesses from a
# particular domain, and the script assumes it's looking at a separate
# visit.

# This regular expression chooses which file suffixes are counted as HTML.
$html_types = "html\$\|htm\$\|shtml\$\|cgi\$\|html-ssi\$\|asp\$\|pl\$\|php\$";
$nodetails_extensions = "gif\$\|jpg\$\|png\$\|au\$\|mp2\$\|mp3\$\|wav\$\|css\$\|swf\$|ico\$";
$nocumpage_extensions = "gif\$\|jpg\$\|png\$\|au\$\|mp2\$\|mp3\$\|wav\$\|css\$\|swf\$";
$sound_extensions = "au\$\|mp2\$\|mp3\$\|wav\$";
$download_extensions = "exe\$\|zip\$\|z\$\|hqx\$\|sit\$\|pdf\$";
$sourcefile_extensions = "c\$\|h\$\|makefile\$\|java\$\|cpp\$\|pl\$";

# The following are toggles: set the variable to 'yes' to turn the feature
# on, anything else (or comment out the entire line) to turn the feature
# off.

$show_directories = 'no';	# display paths with filenames
$count_pages = 'yes';	# count *.html accesses
$count_gifs = 'no';		# count *.gif accesses
$count_pngs = 'no';		# count *.png accesses
$count_jpegs = 'no';	# count *.jpg accesses
$count_csss = 'no';		# count *.css accesses
$count_downloads = 'yes';	# count *.exe/zip/Z/hqx/sit accesses
$count_sounds = 'no';	# count *.au/mp2/mp3/wav accesses
$count_javas = 'no';	# count *.class accesses
$count_source = 'no';	# count source file accesses
$count_other = 'yes';	# count other accesses
$show_histogram = 'yes';	# show when sessions started
$show_tldsum = 'yes';	# summarize by top level domain
$show_cum = 'yes';		# keep long term stats
$show_referrer = 'yes';	# show interesting referrers in details
$show_browser = 'yes';	# show report by browser
$show_class = 'yes';	# show report by visit class
$show_engine = 'yes';	# show report by search engine
$show_query = 'yes';	# show report by query string
$show_visit_list = 'yes';     # show the list of visits
$show_each_hit = 'yes';       # show each visit's hits in detail
$show_illegal_refers = 'yes';	# report on links to non-html
$show_analysis = 'yes';	# show derived figures
$show_referrer_hist = 'yes';	# keep a log of referrers
$show_retcodes = 'no';	# show analysis by return code
$show_verbs = 'no';	# show analysis by transaction verb
$hotlink_html_prefix = '-';	# '-' if not hotlinked, else a prefix on the link, end in /
$show_indexer_details = 'yes'; # if YES, show sessions by indexers
$do_reverse_dns = 'no';	# if YES, translate numeric domains to names
$do_geoip = 'no';		# if YES, translate numeric domains to geo IP
$dnscache_file = '';	# if nonblank, pathname of the DNS cache file
$geoip_file = 'GeoIPCountryWhois.csv'; # if nonblank, pathname of the Geoip file
$show_browser_in_details = 'no'; # if YES, show browser name in details
$min_details_session = 1;	# Don't show sessions with less than this number
$cumulate_search_terms = 'yes'; # put search terms in cumreferrer.hit
$javapie = 'yes';		# Show java pie chart if in HTML mode

# If we are showing various histograms, we may show only the top N lines.
# in your .rc file, remember to put quotes around the numbers, thus:
#
#   $nshowpages = '100';
#
# or it won't pick up the specification.  The dollar and semicolon are also required.
# The .rc file syntax is very picky. Sorry.

$nshowpages = '10000';		# number of today's HTML pages to show
$nshowbrowserhits = '10000';	# number of today's browser hits to show
$nshowtopleveldomains = '10000'; # number of today's toplevel domains to show
$nshowbusydomains = '10000';	# number of today's full domains to show
$nshowbrowserhits = '10000';	# number of today's browser hits to show
$nshowqueryhits = '10000';	# number of today's query hits to show
$nshowreferrerhits = '10000';	# number of today's referrer hits to show
$nshowengine = '10000';		# number of today's engines to show
$nshowbusycumpages = '10000';	# number of busy pages to show longterm
$nshowcumtldvisits = '10000';	# number of cumulative visits by tld to show
$nshowcumreferrers = '10000';	# number of cumulative visits by referrer to show
$nshowclasshits = '10000';	# number of classes to show

# The summary by referrer should ignore references from one page at your
# site to another.  To do this, put lines like the following in your .rc file:
#
#    $kill_referrer = "http://www.best.com/~yourid/";
#
# These will be regular-expression matched against the lowercased referrer value.  
# You don't need to backslash slashes in your string.
# You can put any number of these lines, to treat multiple sites as local.

$nkill_referrer = -1;		# The highest subscript of these entries so far.

# Many people have asked to be able to ignore their own hits on their site.
# To do this, put lines like the following in your .rc file:
#
#    $ignore_hits_from = "yourid.vip.best.com";
#
# You can put any number of these lines, too.  Again this is a RE match and
# is matched against a lowercased version of the site name.  You may wish to
# put in your IP number as well in case the log doesn't put the name in, 
# happens sometimes at BEST when reverse name lookup stops working.

$nignore_hits_from = -1;

# By default the program summarizes hits by toplevel domain, e.g. ".com".
# You can have it treat some domains as if they were toplevel, by adding
# any number of configuration lines of the form
#
#   $special_domain = ".aol.com"

$nspecial_domain = -1;

# The program can count accesses by web indexers, and indicate what percent of
# your total accesses came from them.

$nrobot = -1;
$nrobotdom = -1;

# Preprocessing can be done on urls, filenames, domains, and referrers

$npre_url = -1;
$npre_file = -1;
$npre_referrer = -1;
$npre_domain = -1;

# A chart can be printed to classify and summarize browsers.

$nbrowser_wars = -1;

# A chart can be printed to classify and summarize platforms.

$nplatform_wars = -1;

# The program can report on what percentage of your hits and visits came from
# designated head pages.  You can tell it what a head page is.

$nheadpage = -1;

# Webtrax will watch for certain file names and show them in a chosen css format

$ninred = -1;
$inred[0] = '';
$inredclass[0] = '';

# The program detects some queries as coming from search engines
# according to the following tables.  You can add to the tables from the .rc file
# with a statement of the form
#
#           $query = "lycos?http:\/\/.*lycos.*\/cgi-bin\/pursuit?query=([^&]+)";
#
#               in which the three parts (name, detector, and query extractor)
#               are specified separated by question marks.  The second two are
#               regular expressions with literal characters backslashed.
#
# It's a little tricky, I match the detector against a downcased name
# but the query extractor is exact case.  I removed a ton of these
# and made "extractquery" smarter.

$engine_name[0] = 'infoseek';
$engine_detector[0] = 'javascript:top.buf.';
$engine_query[0] = '&qt=([^&]+)';
$engine_name[1] = 'images.google';
$engine_detector[1] = 'images\.google\.com\/imgres';
$engine_query[1] = '&q=([^&]+)';

$nengines = 1;			# subscript of the last filled entry in the table

# Visit classification works like this: specify one or more "classes" for
# your pages by adding lines of the form
#     $class = "pagename:class1,class2,class3";
# to your webtrax.rc file.  The program will then examine the sequence of
# hits and classify the visit according to the kinds of pages visited.
# The commas represent pages that could fall into more than one category.
# Webtrax will attempt to choose the most appropriate class for a visit.
# For example, if page a.html is classified class1,class2 and page b.html
# is classified class2, then a visit that references both should be
# classified just "class2".  If a.html were classified only class1, then
# the visit would be classified "class1>class2".  If you don't use this
# feature you don't get the report.

################################################################
# You're welcome to use this program however you like.  I used
# it with Best Internet Services' automatically generated user log files,
# and later with Pair Communications' automatically generated user log files,
# which cover one day's worth of accesses and show up in the public_html
# directory early each morning (assuming you have placed a file called
# .logctl in your public_html directory, and put a line containing only
# the number "1" -- without the quotes -- in it). If you want to use this
# script with a log file that does not limit itself to one day's worth of
# accesses, you may wish to extract only the lines pertaining to a specific
# period (like yesterday, or last week), and run the script on that, rather
# than the entire log file.
#
# I run this script from a daily cron job. Use
#
# crontab filename
#
# to set it up, with the file "filename" containing something like the
# following line:
#
# 47 8 * * * cd public_html; ./webtrax.pl webtrax.rc
#
# John Callender
# Tom Van Vleck
#
################################################################

# Classification of transaction verbs (rfc2616). 1 = this is a hit
# (no command interface to set these)
$transaction_verb_type{'GET'} = 1;
$transaction_verb_type{'POST'} = 1;
$transaction_verb_type{'HEAD'} = 0;
$transaction_verb_type{'OPTIONS'} = 0;
$transaction_verb_type{'PUT'} = 0;

# Classification of server retcodes (rfc2616). 1 = this is a hit, 2 = not a hit but show in details
# set by rettype command
$rettype{100} = 0; # Continue
$rettype{101} = 0; # Switching Protocols
$rettype{200} = 1; # OK (count as a hit)
$rettype{201} = 0; # Created
$rettype{202} = 0; # Accepted
$rettype{203} = 0; # Non-Authoritative Information
$rettype{204} = 0; # No Content
$rettype{205} = 0; # Reset Content
$rettype{206} = 1; # Partial Content (count as a hit)
$rettype{300} = 0; # Multiple Choices
$rettype{301} = 0; # Moved Permanently (e.g. redirect from a directory to its index)
$rettype{302} = 0; # Moved Temporarily (e.g. redirect statement in .htaccess)
$rettype{303} = 0; # See Other
$rettype{304} = 1; # Not Modified (e.g. your cached copy is OK (conditional GET)) (count as a hit by default)
$rettype{305} = 0; # Use Proxy
$rettype{307} = 0; # Temporary redirect
$rettype{400} = 0; # Bad Request
$rettype{401} = 0; # Unauthorized
$rettype{402} = 0; # Payment Required
$rettype{403} = 0; # Forbidden (e.g. my .htaccess forbids image theft, mod_rewrite returns [F])
$rettype{404} = 0; # Not Found (change this to 2 with rettype to list 404s in the details)
$rettype{405} = 0; # Method Not Allowed (e.g. WebDAV attempt to PUT)
$rettype{406} = 0; # Not Acceptable
$rettype{407} = 0; # Proxy Authentication Required
$rettype{408} = 0; # Request Timeout
$rettype{409} = 0; # Conflict
$rettype{410} = 0; # Gone
$rettype{411} = 0; # Length Required
$rettype{412} = 0; # Precondition Failed
$rettype{413} = 0; # Request Entity Too Large
$rettype{414} = 0; # Request-URI Too Long
$rettype{415} = 0; # Unsupported Media Type
$rettype{416} = 0; # Requested range not satisfiable
$rettype{417} = 0; # Expectation failed
$rettype{500} = 0; # Internal Server Error
$rettype{501} = 0; # Not Implemented
$rettype{502} = 0; # Bad Gateway
$rettype{503} = 0; # Service Unavailable
$rettype{504} = 0; # Gateway Timeout
$rettype{505} = 0; # HTTP Version Not Supported

$retname{100} = 'Continue';
$retname{101} = 'Switching Protocols';
$retname{200} = 'OK';
$retname{201} = 'Created';
$retname{202} = 'Accepted';
$retname{203} = 'Non-Authoritative Information';
$retname{204} = 'No Content';
$retname{205} = 'Reset Content';
$retname{206} = 'Partial Content';
$retname{300} = 'Multiple Choices';
$retname{301} = 'Moved Permanently';
$retname{302} = 'Moved Temporarily';
$retname{303} = 'See Other';
$retname{304} = 'Not Modified';
$retname{305} = 'Use Proxy';
$retname{400} = 'Bad Request';
$retname{401} = 'Unauthorized';
$retname{402} = 'Payment Required';
$retname{403} = 'Forbidden';
$retname{404} = 'Not Found';
$retname{405} = 'Method Not Allowed';
$retname{406} = 'Not Acceptable';
$retname{407} = 'Proxy Authentication Required';
$retname{408} = 'Request Timeout';
$retname{409} = 'Conflict';
$retname{410} = 'Gone';
$retname{411} = 'Length Required';
$retname{412} = 'Precondition Failed';
$retname{413} = 'Request Entity Too Large';
$retname{414} = 'Request-URI Too Long';
$retname{415} = 'Unsupported Media Type';
$retname{500} = 'Internal Server Error';
$retname{501} = 'Not Implemented';
$retname{502} = 'Bad Gateway';
$retname{503} = 'Service Unavailable';
$retname{504} = 'Gateway Timeout';
$retname{505} = 'HTTP Version Not Supported';

# class for this hit by return code
$retcolor{100} = '';
$retcolor{101} = '';
$retcolor{200} = ''; # ok, black
$retcolor{201} = '';
$retcolor{202} = '';
$retcolor{203} = '';
$retcolor{204} = '';
$retcolor{205} = '';
$retcolor{206} = ''; # partial, black
$retcolor{300} = '';
$retcolor{301} = '';
$retcolor{302} = '';
$retcolor{303} = '';
$retcolor{304} = ''; # cached, "cac" = pink
$retcolor{305} = '';
$retcolor{307} = '';
$retcolor{400} = '';
$retcolor{401} = '';
$retcolor{402} = '';
$retcolor{403} = '';
$retcolor{404} = ''; # file not found, "fnf" = gray
$retcolor{405} = '';
$retcolor{406} = '';
$retcolor{407} = '';
$retcolor{408} = '';
$retcolor{409} = '';
$retcolor{410} = '';
$retcolor{411} = '';
$retcolor{412} = '';
$retcolor{413} = '';
$retcolor{414} = '';
$retcolor{415} = '';
$retcolor{416} = '';
$retcolor{417} = '';
$retcolor{500} = '';
$retcolor{501} = '';
$retcolor{502} = '';
$retcolor{503} = '';
$retcolor{504} = '';
$retcolor{505} = '';

# Explanation of domain suffixes
$countrynames{'.ad'} = "Andorra";
$countrynames{'.ae'} = "United Arab Emirates";
$countrynames{'.af'} = "Afghanistan";
$countrynames{'.ag'} = "Antigua and Barbuda";
$countrynames{'.ai'} = "Anguilla";
$countrynames{'.al'} = "Albania";
$countrynames{'.am'} = "Armenia";
$countrynames{'.an'} = "Netherlands Antilles";
$countrynames{'.ao'} = "Angola";
$countrynames{'.aq'} = "Antarctica";
$countrynames{'.ar'} = "Argentina";
$countrynames{'.as'} = "American Samoa";
$countrynames{'.at'} = "Austria";
$countrynames{'.au'} = "Australia";
$countrynames{'.aw'} = "Aruba";
$countrynames{'.az'} = "Azerbaijan";
$countrynames{'.ba'} = "Bosnia and Herzegovina";
$countrynames{'.bb'} = "Barbados";
$countrynames{'.bd'} = "Bangladesh";
$countrynames{'.be'} = "Belgium";
$countrynames{'.bf'} = "Burkina Faso";
$countrynames{'.bg'} = "Bulgaria";
$countrynames{'.bh'} = "Bahrain";
$countrynames{'.bi'} = "Burundi";
$countrynames{'.bj'} = "Benin";
$countrynames{'.bm'} = "Bermuda";
$countrynames{'.bn'} = "Brunei Darussalam";
$countrynames{'.bo'} = "Bolivia";
$countrynames{'.br'} = "Brazil";
$countrynames{'.bs'} = "Bahamas";
$countrynames{'.bt'} = "Bhutan";
$countrynames{'.bv'} = "Bouvet Island";
$countrynames{'.bw'} = "Botswana";
$countrynames{'.by'} = "Belarus";
$countrynames{'.bz'} = "Belize";
$countrynames{'.ca'} = "Canada";
$countrynames{'.cc'} = "Cocos (Keeling) Islands";
$countrynames{'.cf'} = "Central African Republic";
$countrynames{'.cg'} = "Congo";
$countrynames{'.ch'} = "Switzerland";
$countrynames{'.ci'} = "Cote D'Ivoire (Ivory Coast)";
$countrynames{'.ck'} = "Cook Islands";
$countrynames{'.cl'} = "Chile";
$countrynames{'.cm'} = "Cameroon";
$countrynames{'.cn'} = "China";
$countrynames{'.co'} = "Colombia";
$countrynames{'.cr'} = "Costa Rica";
$countrynames{'.cs'} = "Czechoslovakia (former)";
$countrynames{'.cu'} = "Cuba";
$countrynames{'.cv'} = "Cape Verde";
$countrynames{'.cx'} = "Christmas Island";
$countrynames{'.cy'} = "Cyprus";
$countrynames{'.cz'} = "Czech Republic";
$countrynames{'.de'} = "Germany";
$countrynames{'.dj'} = "Djibouti";
$countrynames{'.dk'} = "Denmark";
$countrynames{'.dm'} = "Dominica";
$countrynames{'.do'} = "Dominican Republic";
$countrynames{'.dz'} = "Algeria";
$countrynames{'.ec'} = "Ecuador";
$countrynames{'.ee'} = "Estonia";
$countrynames{'.eg'} = "Egypt";
$countrynames{'.eh'} = "Western Sahara";
$countrynames{'.er'} = "Eritrea";
$countrynames{'.es'} = "Spain";
$countrynames{'.et'} = "Ethiopia";
$countrynames{'.fi'} = "Finland";
$countrynames{'.fj'} = "Fiji";
$countrynames{'.fk'} = "Falkland Islands (Malvinas)";
$countrynames{'.fm'} = "Micronesia";
$countrynames{'.fo'} = "Faroe Islands";
$countrynames{'.fr'} = "France";
$countrynames{'.fx'} = "France, Metropolitan";
$countrynames{'.ga'} = "Gabon";
$countrynames{'.gb'} = "Great Britain (UK)";
$countrynames{'.gd'} = "Grenada";
$countrynames{'.ge'} = "Georgia";
$countrynames{'.gf'} = "French Guiana";
$countrynames{'.gh'} = "Ghana";
$countrynames{'.gi'} = "Gibraltar";
$countrynames{'.gl'} = "Greenland";
$countrynames{'.gm'} = "Gambia";
$countrynames{'.gn'} = "Guinea";
$countrynames{'.gp'} = "Guadeloupe";
$countrynames{'.gq'} = "Equatorial Guinea";
$countrynames{'.gr'} = "Greece";
$countrynames{'.gs'} = "S. Georgia and S. Sandwich Isls.";
$countrynames{'.gt'} = "Guatemala";
$countrynames{'.gu'} = "Guam";
$countrynames{'.gw'} = "Guinea-Bissau";
$countrynames{'.gy'} = "Guyana";
$countrynames{'.hk'} = "Hong Kong";
$countrynames{'.hm'} = "Heard and McDonald Islands";
$countrynames{'.hn'} = "Honduras";
$countrynames{'.hr'} = "Croatia (Hrvatska)";
$countrynames{'.ht'} = "Haiti";
$countrynames{'.hu'} = "Hungary";
$countrynames{'.id'} = "Indonesia";
$countrynames{'.ie'} = "Ireland";
$countrynames{'.il'} = "Israel";
$countrynames{'.in'} = "India";
$countrynames{'.io'} = "British Indian Ocean Territory";
$countrynames{'.iq'} = "Iraq";
$countrynames{'.ir'} = "Iran";
$countrynames{'.is'} = "Iceland";
$countrynames{'.it'} = "Italy";
$countrynames{'.jm'} = "Jamaica";
$countrynames{'.jo'} = "Jordan";
$countrynames{'.jp'} = "Japan";
$countrynames{'.ke'} = "Kenya";
$countrynames{'.kg'} = "Kyrgyzstan";
$countrynames{'.kh'} = "Cambodia";
$countrynames{'.ki'} = "Kiribati";
$countrynames{'.km'} = "Comoros";
$countrynames{'.kn'} = "Saint Kitts and Nevis";
$countrynames{'.kp'} = "Korea (North)";
$countrynames{'.kr'} = "Korea (South)";
$countrynames{'.kw'} = "Kuwait";
$countrynames{'.ky'} = "Cayman Islands";
$countrynames{'.kz'} = "Kazakhstan";
$countrynames{'.la'} = "Laos";
$countrynames{'.lb'} = "Lebanon";
$countrynames{'.lc'} = "Saint Lucia";
$countrynames{'.li'} = "Liechtenstein";
$countrynames{'.lk'} = "Sri Lanka";
$countrynames{'.lr'} = "Liberia";
$countrynames{'.ls'} = "Lesotho";
$countrynames{'.lt'} = "Lithuania";
$countrynames{'.lu'} = "Luxembourg";
$countrynames{'.lv'} = "Latvia";
$countrynames{'.ly'} = "Libya";
$countrynames{'.ma'} = "Morocco";
$countrynames{'.mc'} = "Monaco";
$countrynames{'.md'} = "Moldova";
$countrynames{'.mg'} = "Madagascar";
$countrynames{'.mh'} = "Marshall Islands";
$countrynames{'.mk'} = "Macedonia";
$countrynames{'.ml'} = "Mali";
$countrynames{'.mm'} = "Myanmar";
$countrynames{'.mn'} = "Mongolia";
$countrynames{'.mo'} = "Macau";
$countrynames{'.mp'} = "Northern Mariana Islands";
$countrynames{'.mq'} = "Martinique";
$countrynames{'.mr'} = "Mauritania";
$countrynames{'.ms'} = "Montserrat";
$countrynames{'.mt'} = "Malta";
$countrynames{'.mu'} = "Mauritius";
$countrynames{'.mv'} = "Maldives";
$countrynames{'.mw'} = "Malawi";
$countrynames{'.mx'} = "Mexico";
$countrynames{'.my'} = "Malaysia";
$countrynames{'.mz'} = "Mozambique";
$countrynames{'.na'} = "Namibia";
$countrynames{'.nc'} = "New Caledonia";
$countrynames{'.ne'} = "Niger";
$countrynames{'.nf'} = "Norfolk Island";
$countrynames{'.ng'} = "Nigeria";
$countrynames{'.ni'} = "Nicaragua";
$countrynames{'.nl'} = "Netherlands";
$countrynames{'.no'} = "Norway";
$countrynames{'.np'} = "Nepal";
$countrynames{'.nr'} = "Nauru";
$countrynames{'.nt'} = "Neutral Zone";
$countrynames{'.nu'} = "Niue";
$countrynames{'.nz'} = "New Zealand (Aotearoa)";
$countrynames{'.om'} = "Oman";
$countrynames{'.pa'} = "Panama";
$countrynames{'.pe'} = "Peru";
$countrynames{'.pf'} = "French Polynesia";
$countrynames{'.pg'} = "Papua New Guinea";
$countrynames{'.ph'} = "Philippines";
$countrynames{'.pk'} = "Pakistan";
$countrynames{'.pl'} = "Poland";
$countrynames{'.pm'} = "St. Pierre and Miquelon";
$countrynames{'.pn'} = "Pitcairn";
$countrynames{'.pr'} = "Puerto Rico";
$countrynames{'.pt'} = "Portugal";
$countrynames{'.pw'} = "Palau";
$countrynames{'.py'} = "Paraguay";
$countrynames{'.qa'} = "Qatar";
$countrynames{'.re'} = "Reunion";
$countrynames{'.ro'} = "Romania";
$countrynames{'.ru'} = "Russian Federation";
$countrynames{'.rw'} = "Rwanda";
$countrynames{'.sa'} = "Saudi Arabia";
$countrynames{'.sb'} = "Solomon Islands";
$countrynames{'.sc'} = "Seychelles";
$countrynames{'.sd'} = "Sudan";
$countrynames{'.se'} = "Sweden";
$countrynames{'.sg'} = "Singapore";
$countrynames{'.sh'} = "St. Helena";
$countrynames{'.si'} = "Slovenia";
$countrynames{'.sj'} = "Svalbard and Jan Mayen Islands";
$countrynames{'.sk'} = "Slovak Republic";
$countrynames{'.sl'} = "Sierra Leone";
$countrynames{'.sm'} = "San Marino";
$countrynames{'.sn'} = "Senegal";
$countrynames{'.so'} = "Somalia";
$countrynames{'.sr'} = "Suriname";
$countrynames{'.st'} = "Sao Tome and Principe";
$countrynames{'.su'} = "USSR (former)";
$countrynames{'.sv'} = "El Salvador";
$countrynames{'.sy'} = "Syria";
$countrynames{'.sz'} = "Swaziland";
$countrynames{'.tc'} = "Turks and Caicos Islands";
$countrynames{'.td'} = "Chad";
$countrynames{'.tf'} = "French Southern Territories";
$countrynames{'.tg'} = "Togo";
$countrynames{'.th'} = "Thailand";
$countrynames{'.tj'} = "Tajikistan";
$countrynames{'.tk'} = "Tokelau";
$countrynames{'.tm'} = "Turkmenistan";
$countrynames{'.tn'} = "Tunisia";
$countrynames{'.to'} = "Tonga";
$countrynames{'.tp'} = "East Timor";
$countrynames{'.tr'} = "Turkey";
$countrynames{'.tt'} = "Trinidad and Tobago";
$countrynames{'.tv'} = "Tuvalu";
$countrynames{'.tw'} = "Taiwan";
$countrynames{'.tz'} = "Tanzania";
$countrynames{'.ua'} = "Ukraine";
$countrynames{'.ug'} = "Uganda";
$countrynames{'.uk'} = "United Kingdom";
$countrynames{'.um'} = "US Minor Outlying Islands";
$countrynames{'.us'} = "United States";
$countrynames{'.uy'} = "Uruguay";
$countrynames{'.uz'} = "Uzbekistan";
$countrynames{'.va'} = "Vatican City State (Holy See)";
$countrynames{'.vc'} = "Saint Vincent and the Grenadines";
$countrynames{'.ve'} = "Venezuela";
$countrynames{'.vg'} = "Virgin Islands (British)";
$countrynames{'.vi'} = "Virgin Islands (U.S.)";
$countrynames{'.vn'} = "Viet Nam";
$countrynames{'.vu'} = "Vanuatu";
$countrynames{'.wf'} = "Wallis and Futuna Islands";
$countrynames{'.ws'} = "Samoa";
$countrynames{'.ye'} = "Yemen";
$countrynames{'.yt'} = "Mayotte";
$countrynames{'.yu'} = "Yugoslavia";
$countrynames{'.za'} = "South Africa";
$countrynames{'.zm'} = "Zambia";
$countrynames{'.zr'} = "Zaire";
$countrynames{'.zw'} = "Zimbabwe";
#  $countrynames{'.com'} = "US Commercial";
#  $countrynames{'.edu'} = "US Educational";
#  $countrynames{'.gov'} = "US Government";
#  $countrynames{'.int'} = "International";
#  $countrynames{'.mil'} = "US Military";
#  $countrynames{'.net'} = "Network";
#  $countrynames{'.org'} = "Non-Profit Organization";

$main::geon = 0;
$dnscache_read = 0;             # have we read the DNS cache yet?
$nfv = 0;			# stack of free Visit entries is empty
################################################################
# Phase 1: read in the cumulative files from last run
################################################################
if (open(CUMPAGEHITS, "cumpage.hit")) {
    $year_hits_total = 0;
    $year_page_reset = <CUMPAGEHITS>;
    chop ($year_page_reset);
    while (<CUMPAGEHITS>) {
	chop;
	($page, $hits) = split (/,/, $_);
	$year_hits_by_file{$page} = $hits;
	$year_hits_total += $hits;
    } # while
    close (CUMPAGEHITS);
} else {
    $year_page_reset = '';
} # if open

if (open(CUMTLDHITS, "cumtld.hit")) {
    $year_tld_reset = <CUMTLDHITS>;
    chop ($year_tld_reset);
    while (<CUMTLDHITS>) {
	chop;
	($tld, $x1, $x2, $x3) = split (/,/, $_);
	if ($countrynames{$tld}) {
	    $tld = $tld . ' ' . $countrynames{$tld};
	}
	$year_hits_by_tld{$tld} = $x1;
	$year_size_by_tld{$tld} = $x2;
	$year_visits_by_tld{$tld} = $x3;
    } # while
    close (CUMTLDHITS);
} else {
    $year_tld_reset = '';
} # if open

#mstat(); # not in my version of perl
# another attempt at reaper protection, didn't help.
#dbmopen %year_hits_by_referrer, "yhbr", 0600 or die "can't tie yhbr";
#dbmopen %year_size_by_referrer, "ysbr", 0600 or die "can't tie ysbr";
#dbmopen %year_visits_by_referrer, "yvbr", 0600 or die "can't tie yvbr";

# reaper protection, keep job from getting killed.
# This file can get large and occupy a lot of memory.
# Then I get in trouble for running too big a job at the ISP.
# My solution for now is to manually delete all the lines
# in the file that end in ",1" once in a while.
# Need to figure out what "too big" is and do this pruning
# automatically when writing out.
# >700K bytes was too big on 11/05/01.  ~200K was fine.
if (open(CUMREFERRERHITS, "cumreferrer.hit")) {
    $year_referrer_reset = <CUMREFERRERHITS>;
    chop ($year_referrer_reset);
    while (<CUMREFERRERHITS>) {
	chop;
	($referrer, $x1, $x2, $x3) = split (/,/, $_);
	$year_hits_by_referrer{$referrer} = $x1;
	$year_size_by_referrer{$referrer} = $x2;
	$year_visits_by_referrer{$referrer} = $x3;
    } # while
    close (CUMREFERRERHITS);
} else {
    $year_referrer_reset = '';
} # if open

#####################################################################
# Phase 2: process arguments.  Either a .rc file or a log.
# For .rc file, read it, parse it, and set control variables.
# For log, process all hits in the log and put data in tables in core.
#####################################################################
open(DETAILTEMPOUT, ">$detail_temp_file") || die "cannot write $detail_temp_file";
$nprocessed = 0;
$configfile = 0;
$start_time = '';
$end_time = '';

if ($#ARGV >= 0) {
    for ($i = 0; $i <= $#ARGV; $i++) {
	$tainted = $ARGV[$i];
	if ($tainted =~ /^([- _=\/.,+\w]+)$/) {
	    $mfile = $1;
	} else {
	    $mfile = "";
	}
	if ($mfile =~ /\.rc$/) {
	    &read_config($mfile);
	    $configfile++;
	} else {
	    if ($configfile == 0) {
		&read_config ("webtrax.rc");
		$configfile++;
	    }
	    # this program operates in two modes, ASCII and "html", depending on outfile
	    $html = 1 if $output_file =~ /\.html$/;
	    &process_one_file ($mfile);
	    $nprocessed++;
	}
    } # for
} # if $#ARGV
if ($nprocessed == 0) { # do at least one file
    if ($configfile == 0) {
	&read_config ("webtrax.rc"); # use default config file name
    }
    $html = 1 if $output_file =~ /\.html$/;
    &process_one_file ($log_file); # use default file name or name from config
} # do at least one file

#----------------------------------------------------------------
# Subroutine: process one log file
# leaves last time seen in $end_time
# Uses global: many
# Sets global: many
# Arguments: none

sub process_one_file {
    my $the_log_file = shift;
    my ($dot, $of_extension, $itemx, $ex, $verb, $protocol, $i, $x1, $x2, $killer, $elapsed);
    my ($path, $filename, $extension, $pageclass, $hittype, $file_type, $access_time);
    my ($line, $cursor, $found);
    my ($yy, $word1, $rest, $pfx, $name_start, $new_referrer);
    my ($colon, $seconds, $minutes, $hours, $hourx, $elapsed_time, $question, $junk, $indexer);
    my ($key, $v, $displayfilename);
    my ($visit, $xx, $min, $secs, $minsx, $browser_type, $platform_type, $old_seconds);
    my ($hash, $hashstring, $extensionlength);
    my @items;
    use strict;

    if ($the_log_file =~ /\.gz$|\.z$/i) { # if a zipped file, read with zcat
	open(LOG, "zcat $the_log_file |") or return;
    } else {			# otherwise read regular
	open(LOG, "$the_log_file") or return;
    }
    
    while(<LOG>) { # scan the file
        
# parse each line into tokens delimited by space.
# tokens may be quoted or bracketed if they contain spaces.
        
        chop;
        $line = $_;
	$main::day_raw_total++;	# count of all the records in the input

	$cursor = 0;
        $itemx = 0;
        while ($cursor < length($line)) {
            while (substr($line, $cursor, 1) eq ' ') {
            	$cursor++;	# kill leading blanks
            }
            if (substr($line, $cursor, 1) eq '"') { # quoted string
	        # inside this string, backslash-quote should become a quote
	        my $ws = '';
		my $more = 1;
		$cursor++;
		while (($more == 1) && ($cursor < length($line))) {
		    if (substr($line, $cursor, 2) eq '\\"') {
			$ws .= '"';
			$cursor++; # extra bump
		    } elsif (substr($line, $cursor, 1) eq '"') {
			$more = 0;
		    } else {
			$ws .= substr($line, $cursor, 1);
		    }
		    $cursor++;
		}
            	$items[$itemx++] = $ws;
	    } # quoted string
            elsif (substr($line, $cursor,1) eq '[') { # bracketed string
            	$ex = index(substr($line, $cursor+1), ']');
            	$ex = length($line)-$cursor if $ex < 0;
            	$items[$itemx++] = substr($line, $cursor+1, $ex);
            	$cursor += $ex+2;
            } # bracketed string
            else { # space delimited string
            	$ex = index(substr($line, $cursor), ' ');
            	$ex = length($line)-$cursor if $ex < 0;
            	$items[$itemx++] = substr($line, $cursor, $ex);
            	$cursor += $ex;
            } # space delimited string
        } # while cursor
	if (!defined($items[0])) { # ill formed record
	    $main::day_hits_by_verb{'garbage'}++; # tally hit by verb
	    next;		  # end processing of record
	}
        
# Record is split into $items.  Interpret and normalize fields.
# Standard form: DOMAIN DIR - TIME COMMAND RETCODE SIZE [REFERRER] [BROWSER]
        
        my $referrer = '-';
        my $browser = '-';
        my $query = '-';
        my $engine = '-';
        my $domain = $items[0];	# where the hit came from
        # $accessed_dir = $items[1];	# not used, - at pair
        # $hyphen = $items[2];		# not used
        $access_time = $items[3];	# time of the hit
        my $command = $items[4];	# HTTP command, e.g. "GET pathname protocol", parsed below
        my $retcode = $items[5];	# HTTP return code
	if (!($retcode =~ /^[0-9]+$/)) { # retcode should be all digits
	    print "bad code: $line\n" if $main::debug;
	    next;		# end processing of record
	}
        my $size = $items[6];	# size in bytes
	$size = 0 if $size eq '-'; # 304 responses may have a size of hyphen
	if ($size !~ /^\d+$/) {  # Skip this hit if size is not numeric.. ill formed hit record
	    $main::day_hits_by_verb{'nn size'}++; # tally hit by verb
	    print "bad size: $line\n" if $main::debug;
	    next;		# end processing of record
	}
        if ($itemx > 6) {	# if there is a referrer string in the log
	    $referrer = $items[7];
	    $referrer = '-' if $referrer eq '';
        } # if there is a referrer string in the log

        if ($itemx > 7) {	# if there is a browser string in the log
	    $browser = $items[8];
        } # if there is a browser string in the log

# Parse the domain and extract tld.

        my $tld = $domain;	# Normalize toplevel domain.
        $tld =~ tr/A-Z/a-z/;
        my $geoip = '';
        $domain =~ s/\.$//;	# Get one or two of these a month.
        if ($domain =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\[(.*)\]$/) {
	    $geoip = $1;	# preprocessed by logextractor
	    $tld = '.' . $geoip;
        } elsif ($domain =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
	    $geoip = &lookup_geoip($domain) if $main::do_geoip eq 'yes';
	    $domain = &reversedns($domain) if $main::do_reverse_dns eq 'yes';
        }
        for ($i=0; $i <= $main::npre_domain; $i++) { # Preprocess domain
	    eval "\$domain =~ $main::pre_domain[$i]";
        } # Preprocess domain
        # some domains are treated as toplevel even if not, such as AOL
        $found = 0;
        for ($i=0; $i <= $main::nspecial_domain; $i++) {
	    $killer = $main::special_domain[$i];
	    if ($domain =~ /$killer/i) {
		$tld = $killer;
		$found++;
		last;
	    }
        } # for
        if ($found == 0) {	# not special
	    $cursor = rindex ($tld, '.');
	    $tld = substr($tld, $cursor) if $cursor >= 0; # toplevel domain has dot
        } # not special
        if ($tld =~ /^\.\d*$/) { # if tld all digits, ie reversedns didn't work
	    if ($geoip ne '') {
		$tld = '.' . $geoip; # tld is geoip value
		$domain .= '['.$geoip.']'; # domain gets geoip appended
	    } else {
		$tld = 'numeric';
	    }
        }  # if tld all numeric
        if ($main::countrynames{$tld}) { # expand short tld with full country name
	    $tld = $tld . ' ' . $main::countrynames{$tld};
        } elsif (($geoip ne '') && ($tld ne ('.'.$geoip))) {
	    $tld .= '['.$geoip.']'; # if geoip disagrees with tld, show both
	    #$domain .= '['.$geoip.']'; # if geoip disagrees with tld, show both -- should I do this?
        }
        
# Parse the command: "GET pathname protocol".
	($verb, $path, $protocol) = split(/ +/, $command, 3);
        if ($path eq "") {
	    $path = '/index.html'; # malformed log entry with no space in it
        }

# Analysis by verb.  
        $main::day_hits_by_verb{$verb}++; # tally hit by verb
        $main::day_size_by_verb{$verb} += $size;

# Extract the filename.
	$path =~ s/\"/?/g;	# if path contained a loose quote, get rid of it.  Will just mess us up in HTML.
        $path =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg; # fix %escapes

        for ($i=0; $i <= $main::npre_url; $i++) { # Preprocess urls (from Ned)
	    eval "\$path =~ $main::pre_url[$i]";
        } # Preprocess urls

        $question = index($path, '?'); # search term at my site begins
        if ($question > 1){ # yup, there's a search term
	    ($junk, $query) = &extractquery($path);
	    $path = substr($path, 0, $question); # remove query from path
        } # yup, there's a search term
        if (rindex($path, '/') == length($path)-1) { # does path end in slash
	    $path .= 'index.html'; # fix GET statements of the form "GET /abc/"
        }
        for ($i=0; $i <= $main::npre_file; $i++) { # Preprocess filenames
	    eval "\$path =~ $main::pre_file[$i]";
	} # Preprocess filenames
        $filename = $path;
        if ($main::show_directories ne 'yes') { # trim down to the bare filename
	    $name_start = rindex($path, '/'); # last slash
	    if ($name_start >= 0) {
		$filename = substr($path, $name_start+1);
	    }
        } # trim down to the bare filename
        $filename =~ tr/A-Z/a-z/; # Lowercase the filename.
        $dot = rindex($filename, '.'); # Locate last filename period.
        if ($dot >= 0) {
	    $extension = substr($filename, $dot+1);
        } else {
	    $extension = '';
        }
        $hash = index($extension, '#'); # locate # in extension e.g. contacts.html#john
        if ($hash >= 0) {
	    $hashstring = substr($extension, $hash);
	    $extensionlength = length($extension)-length($hashstring);
	    $extension = substr($extension,0,$extensionlength);
        }

# Normalize referrer + search, remove aliases for local references.
	if (($referrer ne '-') && ($referrer ne '')) {
	    $referrer =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg; # Unescape.
	    if ($referrer =~ /^.*\@(.*)$/) {
		$referrer = $1;	# Strip off username and password.
	    }
	    $referrer =~ s/:80\//\//; # Remove port 80 if show explicitly.
	    $referrer =~ s/\.\//\//; # Change ./ to /
	    $referrer =~ s/\n//g; # Remove newline characters.
	    $referrer =~ s/\r//g; # Remove return characters.
	    $referrer =~ s/ +/ /g; # Compress strings of blanks.
	    $referrer =~ s/\++/+/g; # Compress strings of pluses.
	    $referrer =~ s/ $//; # remove trailing blank
	    $referrer =~ s/\.+$//; # remove trailing dots
	    if (substr($referrer, -1, 1) ne '/') { # if it has no trailing slash
		if (index(substr($referrer, 7), '/') == -1) { # if there is no slash in it
		    $referrer =~ s/$/\//; # ensure trailing slash
		} # if there is no slash in it
	    }  # if it has no trailing slash
	}
	# User may specify preprocessing on referrers.
	for ($i=0; $i <= $main::npre_referrer; $i++) {
	    eval "\$referrer =~ $main::pre_referrer[$i]";
	} # for
	# User may wish to treat some referrers as local.
	for ($i=0; $i <= $main::nkill_referrer; $i++) {
	    $killer = $main::kill_referrer[$i];
	    if ($referrer =~ /$killer/i) {
		$referrer = 'local'; # self reference
		last;		     # break for loop
	    }
	} # for

# See if it is a search, and determine the search engine and query.
	my $argx = index($referrer, '?');
	if ($argx > 0) { # if there's an argument
	    $argx = $main::max_referrer_length if $argx > $main::max_referrer_length;
	    $engine = substr($referrer, 0, $argx);
	    $found = 0;
	    for ($i=0; $i <= $main::nengines; $i++) {
		$x1 = $main::engine_detector[$i];
		$x2 = $main::engine_query[$i];
		if ($referrer =~ /^$x1/i) { # found a search engine
		    $found = 1;
		    if (($referrer =~ /$x2&/) || ($referrer =~ /$x2$/)) {
			$query = $1;
		    }
		    $engine = $main::engine_name[$i];
		    $referrer = $main::engine_name[$i];
		    last;	# break for loop
		} # found a search engine
	    } # for
	    if ($found == 0) { # if no match on engines
		($referrer, $query) = &extractquery($referrer);
	    } # if no match on engines
	} # if there's an argument

# Normalize query: could come from referrer or from ? string on URL.
	if ($query ne '-') {
	    $query =~ tr/+/ /; # remove the plus signs
	    $query =~ s/\"//g; # and quotes
	    $query =~ s/ +/ /g; # compress strings of blanks
	    $query =~ s/ $//;  # Remove trailing blank
	    $query =~ s/^ //;  # and leading blank
	    if ($query ne '') {
		if (($referrer eq 'local') || ($referrer eq '-')) {
		    $referrer = $query; # a search on my site
		} else {
		    $referrer .= ':'. $query;
		}
	    }
	    $query = substr($query, 0, $main::max_query_length) if length($query) > $main::max_query_length;
	} # query ne -

# Create downcased referrer_down for use as array subscript.
        my $referrer_down = $referrer;
        $referrer_down =~ tr/A-Z/a-z/;
        $referrer_down = substr($referrer_down, 0, $main::max_referrer_length) if length($referrer_down) > $main::max_referrer_length;
        $referrer_down =~ tr/,/./; # Translate comma to dot because of use in cum file.
        $referrer_down = '-' if $referrer eq 'local';
        $engine =~ tr/A-Z/a-z/;	# Downcase engine to combine table rows.

# Normalize browser name.
        ($browser, $indexer, $browser_type, $platform_type) = &detect_browser($browser, $domain);
        # $browser = $platform_type . ' ' . $browser; # DEBUG

# If it's hitting robots.txt, assume it is an indexer.
        if ($filename eq 'robots.txt') {
	    $indexer = 1;
        }

# if there was a query, then it is not an indexer.
        $indexer = 0 if $query ne '-' && $query ne '';
	
# Get the classification of this page access, if any, set in .rc file.
        $pageclass = '';
        if ($indexer == 1) {
	    $pageclass = 'indexer';
        } else { # not indexer
	  if (not defined $main::page_class{$filename}) { # if class not otherwise spec'd
	      $name_start = rindex($path, '/'); # last slash
	      if ($name_start >= 0) {
		  $pageclass = $main::page_class{substr($path, 0, $name_start+1)};
	      }
	  } else {
	      $pageclass = $main::page_class{$filename};
	  }
        } # not indexer
	
# See if this hit is on a "headpage."
        my $hp = 0;
        if ($main::nheadpage >= 0) {
	    for ($i=0; $i <= $main::nheadpage; $i++) {
		$killer = $main::headpage[$i];
		if ($filename =~ /^$killer$/i) {
		    $hp = 1;
		    last;	# break for loop
		}
	    } # for
        } # if $nheadpage
	
# Analysis of the hit to see which type it falls into.
        if ($indexer == 1) {$hittype = 'indexer';}
        elsif (($hp == 1) && ($engine ne '-')) {$hittype = 'search+hp';}
        elsif ($engine ne '-') {$hittype = 'search';}
        elsif ($referrer eq 'local') {$hittype = 'local';}
        elsif (($hp == 1) && ($referrer ne '-')) {$hittype = 'link+hp';}
        elsif ($referrer ne '-') {$hittype = 'link';}
        elsif ($hp == 1) {$hittype = 'hp';}
        else {$hittype = 'other';}

# If size is unreasonable, set it to zero.

        if (($size > 1000000000) || ($size < 0)) { # billion-byte file? nah
	    $size = 0;
        }

# Record is parsed and variables are set.
        
        unless ($main::start_time) { # for "from" part of summary table
	    $main::start_time = $access_time; #remember first time we saw
        }
	
# See if this record should be skipped.
        for ($i=0; $i <= $main::nignore_hits_from; $i++) {
	    $killer = $main::ignore_hits_from[$i];
	    if ($domain =~ /$killer/i) {
		$filename = '...'; # Skip this hit.
		last;
	    }
        } # for
	if ($filename eq '...') {  # ignoring hit because of domain
	    next;		  # end processing of record
	}
	if ($filename eq '') {  # skip if no filename, e.g. "GET /dir_name/" -- web server will redirect and hit again
	    next;		  # end processing of record
	}
	
# Analysis by server return code.
        $main::day_rec_total++;	# count raw log records
        $main::day_rec_size += $size;
        $main::day_hits_by_retcode{$retcode}++; # tally hit by return code
        $main::day_size_by_retcode{$retcode} += $size;
        $main::day_notfound{$path}++ if ($main::count_notfound eq 'yes') && ($retcode eq '404');
	if ($main::rettype{$retcode} == 0) { # if this is a non-hit, no more to do
	    next;		# end processing of record
	}
        
# Ignore further processing if not GET or POST. 
        next if $main::transaction_verb_type{$verb} != 1; # don't display HEAD requests, etc even if 200

# Generate the data for the summary section.
	if ($main::rettype{$retcode} == 1) { # if this is a real hit
	    $main::day_hits_total++; # tally total hits
	    #	$main::day_size_total += $size; # and size (nobody uses this)
	    $main::day_mb_total += ($size / 1048576); # tally traffic flow in mb
	    $main::year_hits_by_file{$filename}++;
	    $main::year_hits_total++;
	    # hmm, this assumes that hits are logged in order.. will be wrong sometimes
	    $main::day_hits_caused_by_page{$main::causing_page_by_domain{$domain}} ++ if defined ($main::causing_page_by_domain{$domain});
	    $main::day_size_caused_by_page{$main::causing_page_by_domain{$domain}} += $size if defined ($main::causing_page_by_domain{$domain});
	    # count hits per toplevel domain and per domain
	    $main::day_hits_by_tld{$tld}++; # count hits for toplevel domain
	    $main::day_size_by_tld{$tld} += $size;
	    $main::year_hits_by_tld{$tld}++;
	    $main::year_size_by_tld{$tld} += $size;
	    $main::day_hits_by_domain{$domain}++; # count hits for whole domain
	    $main::day_size_by_domain{$domain} += $size;
	
	    if ($extension =~ /$main::html_types/o) { # extension is downcased
		#print "** $command **\n" if $filename eq "index.html"; ## debug
		$main::day_html_hits_by_page{$filename}++ if $main::count_pages eq 'yes';
		# stripe the hits on file name by hit type
		$main::day_html_hits_by_page_by_hittype{$filename}{$hittype}++ if $main::count_pages eq 'yes';
		$main::causing_page_by_domain{$domain} = $filename;
		$main::day_html_hits_total++;
		$file_type = 'html';
	    } else {
		if ($extension =~ /^gif$/i) {
		    $main::day_gifs{$filename}++ if $main::count_gifs eq 'yes';
		    $file_type = 'gif';
		} elsif ($extension =~ /^jpg$/i) {
		    $main::day_jpegs{$filename}++ if $main::count_jpegs eq 'yes';
		    $file_type = 'jpg';
		} elsif ($extension =~ /^png$/i) {
		    $main::day_pngs{$filename}++ if $main::count_pngs eq 'yes';
		    $file_type = 'png';
		} elsif ($extension =~ /^css$/i) {
		    $main::day_csss{$filename}++ if $main::count_csss eq 'yes';
		    $file_type = 'css';
		} elsif ($extension =~ /$main::download_extensions/i) {
		    $main::day_downloads{$filename}++ if $main::count_downloads eq 'yes';
		    $file_type = 'binary';
		} elsif ($extension =~ /$main::sound_extensions/i) {
		    $main::day_sounds{$filename}++ if $main::count_sounds eq 'yes';
		    $file_type = 'snd';
		} elsif ($extension =~ /^class$/i) {
		    $main::day_javas{$filename}++ if $main::count_javas eq 'yes';
		    $file_type = 'java';
		} elsif ($extension =~ /$main::sourcefile_extensions/i) {
		    $main::day_source{$filename}++ if $main::count_source eq 'yes';
		    $file_type = 'source';
		} else {
		    # what about a filename like "#taga"?  It should have been
		    # .. handled by the browser, but some idiot sent it to me.
		    $main::day_other{$filename}++ if $main::count_other eq 'yes';
		    $file_type = 'other';
		}
		# check if this page was "illegally" referred, e.g. image theft
		if (($referrer ne 'local') && ($referrer ne '-') &&
		    ($file_type ne 'source') &&	# source files are OK
		    ($engine eq '-') &&	# search engine files are OK (ie ? in query)
		    !($filename =~ /robots\.txt/i)) { # robots.txt is OK
		    $main::day_hits_illref_total++;
		    $key = $referrer . ' ... ' . $filename;
		    $main::day_hits_illref{$key}++;
		    $main::day_size_illref{$key} += $size;
		}
	    } # if extension
	    $main::day_hits_by_file_type{$file_type}++;
	
	    $main::day_hits_by_hittype{$hittype}++;
	    #$main::day_size_by_hittype{$hittype} += $size;

	    $colon = rindex($access_time, ':');	# convert $access_time into seconds since midnight
	    if ($colon < 0) { # ignore records with illegal time format
		$main::day_hits_by_verb{'bad time'}++; # count number of times this happens, actually double counts
		print "bad time: $line\n" if $main::debug;
		next;		# end processing of record
	    }
	    $seconds = substr($access_time, $colon+1, 2);
	    $minutes = substr($access_time, $colon-2, 2);
	    $hours = substr($access_time, $colon-5, 2);
	    $seconds += 3600 * $hours + 60 * $minutes;

	    foreach (keys %main::visit_by_domain) { # Write any visits that have 'expired'.
		$v = $main::visit_by_domain{$_};
		$elapsed = $seconds - $v->{times};
		if ($elapsed < 0) {
		    if (($seconds < 3600) && ($v->{times} > 82800)) {
			# Crossed midnight boundary.
			$elapsed = $seconds + 86400 - $v->{times};
		    } else {
			# Some web servers put entries slightly out of order.
			$elapsed = -($elapsed);
		    }
		} # if elapsed < 0
		if ($elapsed > $main::expire_time) {
		    # Visit has "expired" with $expire_time min of inactivity.
		    &close_visit($v); # print line to detail report
		    delete $main::visit_by_domain{$_}; # clear hash entry
		    $main::freevisits[++$main::nfv] = $v; # place on free stack
		}
	    } # foreach

# count hits in the buckets per hour
	    $hourx = int ($seconds / 3600);
	    $main::day_hits_by_hour[$hourx]++;
	    $main::day_size_by_hour[$hourx] += $size;

# query, engine, referrer and browser
	    unless ($browser eq '-') {
		$main::day_hits_by_browser_total++;
		$main::day_hits_by_browser{$browser}++;
		$main::day_size_by_browser{$browser} += $size;
	    }
	    $new_referrer = 0;
	    unless ($referrer_down eq '-') { # downcased, max 40 chars
		$main::day_hits_by_referrer_total++;
		$main::day_hits_by_referrer{$referrer_down}++;
		$main::day_size_by_referrer{$referrer_down} += $size;
		$main::year_hits_by_referrer{$referrer_down}++;
		$new_referrer = 1 if $main::year_hits_by_referrer{$referrer_down} == 1;
		$main::year_size_by_referrer{$referrer_down} += $size;
	    }
	    unless ($engine eq '-') {
		$main::day_hits_by_engine_total++;
		$main::day_hits_by_engine{$engine}++;
		$main::day_size_by_engine{$engine} += $size;
	    }
	    unless ($query eq '-') {
		$main::day_hits_by_query_total++;
		$main::day_hits_by_query{$query}++;
		$main::day_size_by_query{$query} += $size;
	    }
	} # if this is a real hit

	# ----------------------------------------------
	# Display the hit in a special color based on retcode or filename.
	if ($main::html) {
	    my $cls = '';
	    if ($main::retcolor{$retcode} ne '') {
		$cls = $main::retcolor{$retcode};
	    } else { # Display file name in red if we are watching for it.
		for ($i = 0; $i<=$main::ninred; $i++) {
		    if ($path =~ /$main::inred[$i]/) {
			$cls = $main::inredclass[$i];
			last;	# break for loop
		    }
		} # for
	    } # Display file name in red if we are watching for it.
	    $displayfilename = &escapeHtml($filename);
	    $displayfilename = "<span class=\"$cls\">$displayfilename</span>" if $cls ne '';
	} # if html

	# Add the hit to an open visit or start a new visit.
        if (not defined $main::visit_by_domain{$domain}) { # Is there a visit open for this domain?
	    # No, open a new visit.
	    # Visit counting happens in "close_visit" at end of visit. Save info.
	    if ($main::nfv > 0) {
		$visit = $main::freevisits[$main::nfv--];
	    } else {
		$visit = new Visit;
	    }
	    $main::visit_by_domain{$domain} = $visit;
	    $visit->{pages} = 0;
	    $visit->{domain} = $domain;
	    $visit->{times} = $seconds;
	    $visit->{details} = '';
	    $visit->{hits} = 1;
	    $visit->{size} = $size;
	    $visit->{visitclass} = $pageclass; # is 'indexer' if a spider
	    $visit->{hittype} = $hittype;
	    $visit->{hourx} = $hourx;
	    $visit->{browser} = $browser;
	    $visit->{tld} = $tld;
	    $visit->{referrer} = $referrer_down;
	    $visit->{query} = $query;
	    $visit->{engine} = $engine;
	    $minsx = ($seconds/60) % 60;
	    $minsx = &twodigit($minsx);
	    $hourx = &twodigit($hourx);
	    if ($main::html) {
		$xx = &escapeHtml($domain);
		my $ddclass = '';
		$ddclass = " class=\"indexer\"" if $pageclass eq 'indexer';
		$visit->{details} = "<dt>$hourx:$minsx</dt><dd$ddclass> <span class=\"refdom\">$xx</span>";
	    } else {
		$visit->{details} = "$hourx:$minsx $domain";
	    } # if $html
	    if ($hittype eq 'local') {
		$visit->{details} .= '*'; # flag a new visit that's really a continuation
	    }

	    unless ($extension =~ /$main::nodetails_extensions/io) { # don't display gif/jpg/png etc in details
		if ($main::html) {
		    $visit->{details} .= " -- $displayfilename" if $main::show_each_hit eq 'yes'; # first hit
		} else {
		    $visit->{details} .= " -- $filename" if $main::show_each_hit eq 'yes'; # first hit
		}
		$visit->{pages}++;
	    } # unless $extension
	    if ($browser ne '-') {
		$main::day_visits_by_browser{$browser}++;
		$main::day_visits_by_browser_war{$browser_type}++;
		$main::day_visits_by_platform_war{$platform_type}++;
	    } # if $browser
	# -------------------------    
        } else {		# A subsequent hit from the same domain, add to the visit.
	    $visit = $main::visit_by_domain{$domain};
	    if ($filename =~ /index\.html$/i) { # check for double index.html entry
		next if $visit->{details} =~ /$filename$/i; # xxx bug here, if a file is qindex.html or something
	    }
	    if ($visit->{hittype} eq 'local') { # if a local hit logged first
		$visit->{hittype} = $hittype; # take first non-local hittype
		$visit->{engine} = $engine;
		$visit->{query} = $query;
		$visit->{referrer} = $referrer_down;
	    }
	    $visit->{hits}++;
	    $visit->{size} += $size;
	    $old_seconds = $visit->{times};
	    
	    if ($pageclass eq '') { # classify this visit
		# no class for this page, leave it whatever it was
	    } elsif ($visit->{visitclass} eq '') { 
		$visit->{visitclass} = $pageclass; # previously empty 
	    } elsif ($visit->{visitclass} eq 'indexer') { 
		# ignore pageclass, make whole session indexer
	    } elsif (($xx =index($pageclass, ',')) >= 0) { # ambiguous pageclass
		$yy = 0;
		$word1 = substr($pageclass, 0, $xx); # start with first possible class
		$rest = substr($pageclass, $xx+1);
		while ($word1 ne '') { # check each possible class
		    if (index($visit->{visitclass}, $word1) >= 0) {
			$yy++; # got this class already
		    }
		    last if $rest eq '';
		    $xx = index($rest, ',');
		    if ($xx < 0) {
			$word1 = $rest;
			$rest = '';
		    } else {
			$word1 = substr($rest, 0, $xx);
			$rest = substr($rest, $xx+1);
		    } # if $xx
		} # check each possible class
		if ($yy==0) { # none of these words is already there, ravel ambig
		    $visit->{visitclass} .= ">$pageclass";
		} # none of these words is already there
	    } else { # unambiguous pageclass 
		$word1 = $visit->{visitclass};
		if (($xx = rindex($word1, '>')) >= 0) {
		    $word1 = substr($word1, $xx+1); # pick off last, possibly ambig, class
		    $pfx = substr ($visit->{visitclass}, 0, $xx+1);
		} else {
		    $pfx = '';
		}
		if ($word1 eq $pageclass) {
		    # got this already
		} elsif (index($word1, $pageclass) >= 0) { # ambig class reduction
		    $visit->{visitclass} = $pfx . $pageclass;
		} elsif (index($visit->{visitclass}, $pageclass) >= 0) {
		    # got it already, back jump
		} else {
		    # if visitclass is disjoint with visitclass_by_domain, ravel on end
		    $visit->{visitclass} .= ">$pageclass";
		}
	    } # classify this visit
	    
	    $visit->{times} = $seconds; # updates entry in the open Visit
	    unless ($extension =~ /$main::nodetails_extensions/io) { # don't display gif/jpg in details
		$elapsed = $seconds - $old_seconds;
		if ($elapsed < 0){ # because we're crossing midnight boundary
		    $elapsed = $seconds + 86400 - $old_seconds;
		}
		$min = int($elapsed / 60);
		$secs = &twodigit($elapsed % 60);
		$elapsed_time = "$min:$secs";
		if ($main::html) {
		    $visit->{details} .= " $elapsed_time, $displayfilename" if $main::show_each_hit eq 'yes';
		} else {
		    $visit->{details} .= " $elapsed_time, $filename" if $main::show_each_hit eq 'yes';
		}
		$visit->{pages}++;
	    } # unless $extension
        } # a subsequent entry into the same domain

	# whether new session or old, if there is a referrer, add it to details
	next if $extension =~ /$main::nodetails_extensions/io; # don't display gif/jpg in details
	if ($main::show_referrer) {
	    next if $referrer eq '-'; # if there is a referrer
	    next if $referrer eq 'local';
	    if ($main::show_each_hit eq 'yes') {
		if ($main::html) {
		    $xx = &escapeHtml($referrer);
		    if (($referrer =~ /^http:/i) & !($referrer =~ /\?/)) { # make link live, if safe
			$visit->{details} .= " <a href=\"$referrer\">(";
			$visit->{details} .= "<span class=\"newref\">" if $new_referrer == 1;
			$visit->{details} .= $xx;
			$visit->{details} .= "</span>" if $new_referrer == 1;
			$visit->{details} .= ")</a>";
		    } elsif ($query ne "-") {
			$visit->{details} .= " <span class=\"query\">($xx)</span>";
		    } else {
			$visit->{details} .= " ($xx)";
		    } 
		} else {	# not html
		    $visit->{details} .= " ($referrer)";
		} # if $html
	    } # if show_each_hit
	} # if show_referrer
# ... all the "next"s above come here, read next record.
    } # while <LOG>
    $main::end_time = $access_time; # for "to" part of summary table
    foreach (keys %main::visit_by_domain) { # write out the remaining unexpired lines
	$v = $main::visit_by_domain{$_};
	&close_visit($v);	# print details to report
	delete $main::visit_by_domain{$_};
	$main::freevisits[++$main::nfv] = $v; # place on free stack
    }
    close LOG;
} # process_one_file

################################################################
# Phase 3: Read in the old summary.txt and write a new one.
# Accumulate some totals per month for the report.
# Don't do anything if no hits, otherwise it writes a bad line and truncates summary.
################################################################

if ($day_hits_total > 0) {
    $date1 = substr ($start_time, 0, 17);
    $date2 = substr ($end_time, 0, 17);
    $visits = $day_visits_total;
    $mb = int($day_mb_total);
    $hits = $day_hits_total;
    $pages = $day_html_hits_total;

    # Insert today's figures in the first position of the arrays
    $monthrpt_date1[0] = $date1;
    $monthrpt_date2[0] = $date2;
    $monthrpt_visits[0] = $visits;
    $monthrpt_mb[0] = $mb;
    $monthrpt_hits[0] = $hits;
    $monthrpt_pages[0] = $pages;
    
    $max_day_visits = $visits;
    $max_day_mb = $mb;
    $max_day_hits = $hits;
    $max_day_pages =  $pages;
    $min_day_visits = $visits;
    $min_day_mb = $mb;
    $min_day_hits = $hits;
    $min_day_pages =  $pages;
    $month_visits = $visits;
    $month_mb = $mb;
    $month_hits = $hits;
    $month_pages = $pages;

    # Scan the old summary.txt and add its figures.  Write a new version.
    $daylines = 1;
    $days_with_html_pages = 1;
    open (SUMMARY, ">summary.tmp") or die "webtrax: Can't write summary.tmp"; 
    my $wrote_summary_line = 0;
    if (open (IN, "summary.txt")) { # if old summary.txt existed
	while ($daylines < $month_days) {
	    $summary_line = <IN>;
	    last if $summary_line eq '';
	    my $okline = 1;
	    # parse the summary line, add up $month_visits, $month_mb, and $month_hits
	    if ($summary_line =~ /^(\S+)  (\S+) +(\d+) +(\d+) +(\d+) +(\d+)$/) {
		$xdate1 = $1;
		$xdate2 = $2;
		$xvisits = $3;
		$xmb = $4;
		$xhits = $5;
		$xpages = $6;
		$days_with_html_pages++ if $6 > 0;
	    } elsif ($summary_line =~ /^(\S+)  (\S+) +(\d+) +(\d+) +(\d+)$/) {
		$xdate1 = $1;
		$xdate2 = $2;
		$xvisits = $3;
		$xmb = $4;
		$xhits = $5;
		$xpages = '';	# old style, don't ++days_with_html_pages
	    } else {
		$okline = 0;	# skip this line, can't understand it
	    } # if $summary_line
	    # XXX
	    # XXX check if we wish to merge this summary with previous
	    # XXX cases: xdate2 ~ date1, and not ~midnight, adding onto end
	    # XXX        date2 ~ xdate1, and not ~midnight, did them in wrong order
	    # XXX        disjoint
	    # XXX oops, what if the logs are rolled consistently at e.g. 3AM?
	    # XXX .. what if we only joined things << 24 hours?
	    # XXX
	    if ($wrote_summary_line == 0) { # if didn't write today's line yet
                # write $date1, $date2, $visits, $mb, $hits, $pages
		write SUMMARY; # today's data goes into the 1st line
		$wrote_summary_line = 1;
	    }
	    if ($okline == 1) {
		# copy the vars read from the line into the ones used by the format
		$date1 = $xdate1;
		$date2 = $xdate2;
		$visits = $xvisits;
		$mb = $xmb;
		$hits = $xhits;
		$pages = $xpages;
		# accumulate totals
		$month_visits += $visits;
		$month_mb += $mb;
		$month_hits += $hits;
		$month_pages += $pages;
		$max_day_visits = $visits if $visits > $max_day_visits;
		$max_day_mb = $mb if $mb > $max_day_mb;
		$max_day_hits = $hits if $hits > $max_day_hits;
		$max_day_pages = $pages if $pages > $max_day_pages;
		$min_day_visits = $visits if $visits < $min_day_visits;
		$min_day_mb = $mb if $mb < $min_day_mb;
		$min_day_hits = $hits if $hits < $min_day_hits;
		$min_day_pages = $pages if $pages < $min_day_pages;
		$monthrpt_date1[$daylines] = $date1;
		$monthrpt_date2[$daylines] = $date2;
		$monthrpt_visits[$daylines] = $visits;
		$monthrpt_mb[$daylines] = $mb;
		$monthrpt_hits[$daylines] = $hits;
		$monthrpt_pages[$daylines] = $pages;
		write SUMMARY;		# Write data into summary.txt for next time.
		# $date1, $date2, $visits, $mb, $hits, $pages
		++$daylines;
	    } # if okline
	} # while $daylines
	close IN;
	unlink ("summary.txt");	# Remove the old summary.txt.
    } else {
	write SUMMARY; # first line of a summary, welcome to webtrax.
	# $date1, $date2, $visits, $mb, $hits, $pages
    }
    close IN;
    close SUMMARY;
    rename ("summary.tmp", "summary.txt");
} # if day_hits_total > 0

################################################################
# Phase 4: Create the report by looking at the incore tables.
################################################################

# Heading

$colon = index($end_time, ":");
$today = substr($end_time, 0, $colon);
$year_page_reset = $today if $year_page_reset eq '';
$year_tld_reset = $today if $year_tld_reset eq '';
$year_referrer_reset = $today if $year_referrer_reset eq '';

&print_heading_report($today);

&print_month_summary_report($daylines, 
			    \@monthrpt_date1, 
			    \@monthrpt_date2,
			    \@monthrpt_visits, 
			    \@monthrpt_mb, 
			    \@monthrpt_hits, 
			    \@monthrpt_pages,
			    $min_day_visits, 
			    $min_day_mb, 
			    $min_day_hits, 
			    $min_day_pages,
			    $max_day_visits, 
			    $max_day_mb, 
			    $max_day_hits, 
			    $max_day_pages,
			    $month_visits, 
			    $month_mb, 
			    $month_hits, 
			    $month_pages,
			    $days_with_html_pages);

&print_analysis_report($start_time, 
		       $end_time,
		       \%day_hits_by_file_type, 
		       \%day_hits_by_hittype, 
		       \%day_visits_by_hittype, 
		       \%day_visits_by_class,
		       \%day_visits_by_browser_war, 
		       \%day_visits_by_platform_war, 
		       \%day_html_hits_by_page,
		       $day_hits_total, 
		       $day_visits_total, 
		       $day_hits_by_class_total, 
		       $nbrowser_wars, 
		       $nplatform_wars, 
		       $nengines, 
		       $nrobot,
		       $day_html_hits_total, 
		       $day_nohtml_visits,
		       $day_nohtml_hits,
		       $nheadpage) if $show_analysis eq 'yes';

&print_html_pages_report(\%day_html_hits_by_page, 
			 \%day_hits_caused_by_page, 
			 \%day_size_caused_by_page,
			 \%day_html_hits_by_page_by_hittype,
			 $nshowpages) if $count_pages eq 'yes';

&print_filetype_report(\%day_gifs, "GIFs (*.gif)") if ($count_gifs eq 'yes');
&print_filetype_report(\%day_jpegs, "JPEGs (*.jpg)") if ($count_jpegs eq 'yes');
&print_filetype_report(\%day_pngs, "PNGs (*.png)") if ($count_pngs eq 'yes');

&print_filetype_report(\%day_csss, "CSSs (*.css)") if ($count_csss eq 'yes');

&print_filetype_report(\%day_downloads, "Downloads (*.exe/zip/Z/hqx/sit/pdf)") if ($count_downloads eq 'yes');

&print_filetype_report(\%day_sounds, "Sounds (*.au/mp2/wav)") if ($count_sounds eq 'yes');

&print_filetype_report(\%day_javas, "Java classes (*.class)") if ($count_javas eq 'yes');

&print_filetype_report(\%day_source, "Source (*.c/h/C/java/pl/makefile)") if ($count_source eq 'yes');

&print_filetype_report(\%day_other, "Other files (unrecognized)") if ($count_other eq 'yes');

&print_filetype_report(\%day_notfound, "Files not found") if ($count_notfound eq 'yes');

&print_illref_report(\%day_hits_illref, 
		     \%day_size_illref,
		     $day_hits_illref_total) if ($show_illegal_refers eq 'yes' and $day_hits_illref_total > 0);

&print_accesstime_report(\@day_hits_by_hour,
			 \@day_visits_by_hour,
			 \@day_size_by_hour,
			 \@day_visits_by_hour_by_hittype) if $show_histogram eq 'yes';

# see note on the calling sequence of print_histogram_report
%histo_hit = (); # used as base for typeglob, arg 1.
&print_histogram_report(*day_hits_by_tld, 
			\%day_visits_by_tld, 
			\%day_size_by_tld, 
			"Toplevel Domains", 
			$nshowtopleveldomains, 
			"this period", "hits_tld", $max_key_lth) if $show_tldsum eq 'yes';

&print_histogram_report(*day_hits_by_domain, 
			\%day_visits_by_domain, 
			\%day_size_by_domain, 
			"Domains", 
			$nshowbusydomains, 
			"this period", "hits_domain", $max_domain_length) if $show_tldsum eq 'yes';

&print_cumpage_report(\%year_hits_by_file,
		      $year_hits_total,
		      $nshowbusycumpages,
		      $nocumpage_extensions,
		      $year_page_reset) if $show_cum eq 'yes';

&print_histogram_report(*year_hits_by_tld, 
			\%year_visits_by_tld, 
			\%year_size_by_tld, 
			"Top Level Domains", 
			$nshowcumtldvisits, 
			"since $year_tld_reset", "year_tld", $max_domain_length) if $show_cum eq 'yes';

&print_histogram_report(*day_hits_by_class, 
			\%day_visits_by_class, 
			\%day_size_by_class, 
			"Visit classes", 
			$nshowclasshits, 
			"this period", "class", $max_key_lth) if ($show_class eq 'yes' && $day_hits_by_class_total > 0);

&print_histogram_report(*day_hits_by_browser, 
			\%day_visits_by_browser, 
			\%day_size_by_browser, 
			"Browsers", 
			$nshowbrowserhits, 
			"this period", "browser", $max_key_lth) if ($show_browser eq 'yes' && $day_hits_by_browser_total > 0);

&print_histogram_report(*day_hits_by_query, 
			\%day_visits_by_query, 
			\%day_size_by_query, 
			"Queries", 
			$nshowqueryhits, 
			"this period", "query", $max_key_lth) if ($show_query eq 'yes' && $day_hits_by_query_total > 0);

&print_histogram_report(*day_hits_by_referrer, 
			\%day_visits_by_referrer, 
			\%day_size_by_referrer, 
			"Referrers", 
			$nshowreferrerhits, 
			"this period", "referrer", $max_key_lth) if ($show_referrer eq 'yes' && $day_hits_by_referrer_total > 0);

&print_histogram_report(*year_hits_by_referrer, 
			\%year_visits_by_referrer, 
			\%year_size_by_referrer, 
			"Referring URLs", 
			$nshowcumreferrers, 
			"since $year_referrer_reset", "year_referrer", $max_key_lth) if ($show_referrer_hist eq 'yes');

&print_histogram_report(*day_hits_by_engine, 
			\%day_visits_by_engine, 
			\%day_size_by_engine, 
			"Search Engines", 
			$nshowengine, 
			"this period", "engine", $max_key_lth) if ($show_engine eq 'yes' && $day_hits_by_engine_total > 0);

&print_retcode_report (\%day_hits_by_retcode, 
		       \%day_size_by_retcode, 
		       $day_rec_total, 
		       $day_rec_size) if $show_retcodes eq 'yes';

&print_verb_report (\%day_hits_by_verb, 
		    \%day_size_by_verb, 
		    $day_raw_total, 
		    $day_rec_size) if $show_verbs eq 'yes';

&print_visit_details_report() if $show_visit_list eq 'yes';

&print_tail_report();

#----------------------------------------------------------------
#  Report is done
#----------------------------------------------------------------
# If the user wants the report mailed, mail it.

if ($mailto_address ne '') {
    open (MAIL, 
    	"|$mail_program -s \"$site_name access report for $today\" $mailto_address");
    open (REPORT, "$main::output_file") or die "webtrax: Can't open $main::output_file";
    while (<REPORT>) {
	print MAIL $_;
    }
    close (MAIL);
    close (REPORT);
} # if $mailto

################################################################
# Phase 5: write out the cumulative files for next time.
################################################################
if ($show_cum eq 'yes') {
    open(CUMPAGEHITS, ">cumpage.hit") or die "webtrax: Can't rewrite cumpage.hit";
    print CUMPAGEHITS "$year_page_reset\n";
    foreach (keys %year_hits_by_file) {
	$value = $year_hits_by_file{$_};
	print CUMPAGEHITS "$_,$value\n";
    }
    close (CUMPAGEHITS);

    open(CUMTLDHITS, ">cumtld.hit") or die "webtrax: Can't rewrite cumtld.hit";
    print CUMTLDHITS "$year_tld_reset\n";
    foreach (keys %year_hits_by_tld) {
	$x1 = $year_hits_by_tld{$_};
	$x2 = $year_size_by_tld{$_};
	$x3 = $year_visits_by_tld{$_};
	print CUMTLDHITS "$_,$x1,$x2,$x3\n";
    }
    close (CUMTLDHITS);

    # See comment above about the size of this file.
    # Could put the following block in a loop that repeatedly
    # increases the pruning until the file size is "small enough"
    # where that's a parameter.
    $cumreferrer_pruning_limit = 0;
    open(CUMREFERRERHITS, ">cumreferrer.hit") or die "webtrax: Can't rewrite cumreferrer.hit";
    print CUMREFERRERHITS "$year_referrer_reset\n";
    foreach (keys %year_hits_by_referrer) {
	$x1 = $year_hits_by_referrer{$_};
	$x2 = $year_size_by_referrer{$_};
	$x3 = $year_visits_by_referrer{$_};
	if ((/^http:/) || ($main::cumulate_search_terms eq 'yes')) {
	    if ($x3 > $cumreferrer_pruning_limit) {
		print CUMREFERRERHITS "$_,$x1,$x2,$x3\n";
	    } # if > pruning
	} # if http or cumulate
    } # foreach
    close (CUMREFERRERHITS);
    # stat the file and see if too big, go round again if so.
} # if $show_cum

if (($main::do_reverse_dns eq 'yes') && ($main::dnscache_file ne '')) {
    if (open(DNSCACHE, ">$main::dnscache_file")) {
        binmode DNSCACHE;	# Ned says we need this for DOS.
	foreach (keys %main::dnscache) {
	    $dom = $main::dnscache{$_};
	    $arg = $main::dnscache_arg{$_};
	    print DNSCACHE "$arg $_ $dom\n";
	} # foreach
	close (DNSCACHE);
    } # if open
} # if dnscache_file

#dbmclose %year_hits_by_referrer;
#dbmclose %year_size_by_referrer;
#dbmclose %year_visits_by_referrer;
# delete the .dir and .pag files, wastes space.

################################################################
# end of execution
################################################################

format HEADER =
^||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
$centered_body
.
format SUMMARY =
@<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<  @>>>>>  @#####  @>>>>>  @>>>>>
$date1, $date2, $visits, $mb, $hits, $pages
.
format TOTALS =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$totals_body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
$totals_body

.
format DETAILS =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$details_body
~~    ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$details_body
.
################################################################
#  Subroutines
################################################################

# &close_visit($visit)
# An "open" domain has a string $details beginning with date and time and
# then listing filenames (if turned on).  This function formats this info and writes 
# it out to a temp file when the domain "expires".
# writes global: DETAILTEMPOUT, many totals
sub close_visit { 
# write "expired" (and other) domains from %details_by_domain to report file
    my $visit = shift;
    my $nn = $visit->{hits};
    my $kb = int($visit->{size} / 1024);
    my $vc = $visit->{visitclass};
    my $hittype = $visit->{hittype};
    my $hourx = $visit->{hourx};
    my $browser = $visit->{browser};
    my $yy;
    my $zz;
    my $word1;
    my $details_temp;
use strict;

    #$visit->display();
    $main::day_visits_total++;	# A new visit, count it.
    $main::day_visits_by_hittype{$hittype}++; # now we know the hittype
    $main::day_visits_by_hour[$hourx]++; # histogram of when visits started
    $main::day_visits_by_hour_by_hittype[$hourx]{$hittype}++; # striped by hit type
    $main::day_visits_by_tld{$visit->{tld}}++; # count visits for toplevel domain	    
    $main::day_visits_by_domain{$visit->{domain}}++; # count visits for whole domain
    $main::day_visits_by_referrer{$visit->{referrer}}++ unless $visit->{referrer} eq '-';
    $main::day_visits_by_engine{$visit->{engine}}++ unless $visit->{engine} eq '-';
    $main::day_visits_by_query{$visit->{query}}++ unless $visit->{query} eq '-';
    $main::year_visits_by_tld{$visit->{tld}}++;
    $main::year_visits_by_referrer{$visit->{referrer}}++ unless $visit->{referrer} eq '-';
    if ($vc ne '') { # check classification of visit
	$word1 = $vc;
	if (($zz = index($word1, '>')) >= 0) {
	    $word1 = substr($word1, 0, $zz);
	}
	if (($yy = index($word1, ',')) >= 0) { # if ambiguous, take just first
	    $vc = substr($word1, 0, $yy); # maps x,y>z to x but leaves x>y,z alone
	}
	$main::day_visits_by_class{$vc}++;
	$main::day_size_by_class{$vc} += $visit->{size};
	$main::day_hits_by_class{$vc} += $nn;
	$main::day_hits_by_class_total += $nn;
    } # check classification of visit
    # if not enough html pages were hit, don't print a details entry.
    if ($visit->{pages} < $main::min_details_session) { # check versus minimum number (default 1)
	if ($visit->{pages} == 0) {	       # if no pages at all, count these
	    $main::day_nohtml_visits++;
	    $main::day_nohtml_hits += $visit->{hits};
	}
    } else {
	$details_temp = '';
	if (($vc ne 'indexer') || ($main::show_indexer_details eq 'yes')) {
	    $details_temp .= $visit->{details}; # start time, list of filenames
	    $details_temp .= " ";
	    $details_temp .= "<span class=\"sessd\">" if $main::html;
	    $details_temp .= "[";
	    $details_temp .= "$nn, ";
	    $details_temp .= "$kb";
	    $details_temp .= " KB";
	    if ($main::show_browser_in_details eq 'yes' && $browser ne "-") {
		$details_temp .= ", ";
		if ($main::html) {
		    $details_temp .= "<span class=\"brow\">";
		    $details_temp .= &escapeHtml($browser);
		    $details_temp .= "</span>";
		} else {
		    $details_temp .= $browser;
		}
	    }
	    $details_temp .= "]";
	    $details_temp .= "</span>" if $main::html;
	    if ($vc ne '') {
		$details_temp .= " ";
		$details_temp .= "<span class=\"vc\">" if $main::html;
		$details_temp .= "{";
		$details_temp .= &escapeHtml($vc);
		$details_temp .= "}";
		$details_temp .= "</span>" if $main::html;
	    }
	    $details_temp .= "</dd>" if $main::html;
	    print DETAILTEMPOUT "$details_temp\n";
	}
    } # check versus min_details_session
    undef $visit->{$domain};	# undefine all the contents of this visit
    undef $visit->{$times};
    undef $visit->{$hits};
    undef $visit->{$size};
    undef $visit->{$visitclass};
    undef $visit->{$hittype};
    undef $visit->{$hourx};
    undef $visit->{$browser};
    undef $visit->{$tld};
    undef $visit->{$referrer};
    undef $visit->{$query};
    undef $visit->{$engine};
    undef $visit->{$pages};
    undef $visit->{$details};
} #close_visit

#----------------------------------------------------------------
# $val = &escapeHtml ($field)
sub escapeHtml { # returns field with bad chars escaped for web output
	my $x = shift;
use strict;    
	$x =~ s/&/&amp;/g;
	$x =~ s/</&lt;/g;	# disable markup for security purposes
	$x =~ s/>/&gt;/g;
	$x =~ tr/[0-9][A-Z][a-z]\.,:%;\-\(\)\&\/_+=*^%$\\|\#\~@! /?/c; # remove bad chrs
	return "$x";	
} # escapeHtml

#----------------------------------------------------------------
# $val = &twodigit ($field)
sub twodigit { # returns field with leading zero if necessary
	my $x = shift;
use strict;    
	return "$x" if ($x > 9);
	return "0$x";
} # twodigit

#----------------------------------------------------------------
# $val = &padwidth ($field, $width)
sub padwidth { # returns field padded with blanks on right
	my $x = shift;
	my $y = shift;
	my $z = "$x                                                           ";
use strict;    

	return substr ($z, 0, $y);
} # padwidth

#----------------------------------------------------------------
# $val = &intfmt ($number, $width)
sub intfmt { # returns number right justified
	my $x = shift;
	my $y = shift;
	my $z = "            $x";
use strict;    

	return substr ($z, -$y, $y);
} # intfmt

#----------------------------------------------------------------
# $width = &fldw ($n)
sub fldw { # return number of digits a number will need
	my $x = shift;
use strict;    

    return 1 if ($x <10);
    return 2 if ($x <100);
    return 3 if ($x <1000);
    return 4 if ($x <10000);
    return 5 if ($x <100000);
    return 6 if ($x <1000000);
    return 7 if ($x <10000000);
    return 8 if ($x <100000000);
    return 9 if ($x <1000000000);
    return 10 if ($x <10000000000);
    return 11;
} # fldw

#----------------------------------------------------------------
# ($rferrer, $query) = &extractquery($referrerstring)
sub extractquery {
    my $xreferrer = shift;
    $xreferrer =~ s/%3f/?/ig;
    $xreferrer =~ s/%26/\&/ig;
    $xreferrer =~ s/%3a/:/ig;
    $xreferrer =~ s/%3d/=/ig;
    $xreferrer =~ s/%2b/+/ig;
    $xreferrer =~ s/%2f/\//ig;
    my $xquery = "-";
    my $x1;
    my ($head, $tail) = split(/\?/, $xreferrer, 2);
    $x1 = '&' . $tail . '&';
    $x1 =~ s/&and=|&ask=|&as_q=|&as_epq=|&aw=|&aw0=|&cat=|&fi_1=|&findrequest=|&general=|&ht=|&key=|&keyword=|&keywords=|&kw=|&metatopic=|&mfkw=|&mt=|&oldquery=|&p=|&parole=|&qkw=|&qr=|&qry=|&qs=|&qt=|&query=|&querystring=|&queryterm=|&question=|&r=|&realname=|&request=|&s=|&search=|&search_term=|&searchfor=|&searchstring=|&searchtext=|&searchwd=|&sid=|&ss=|&subid=|&terms=|&text=|&value=|&w=/\&q=/gi;
    if ($x1 =~ /&q=([^&][^&][^&]+)&/) { # if it looks like a query
	$xquery = $1;
	$xreferrer = $head;
	# remove http:// and all after first slash
	if ($xreferrer =~ /http:\/\/([^\/]+)\//) {
	    $xreferrer = $1;
	} elsif ($xreferrer =~ /http:\/\/([^\/]+)/) {
	    $xreferrer = $1;
	}
    } # if it looks like a query
    return ($xreferrer, $xquery);
} # extractquery

# ----------------------------------------------------------------
# ($browser, $indexerflag, $browser_type, $platform_type) = &detect_browser($browserstring, $dom)
sub detect_browser {
    my $ua = shift;
    my $dom = shift;
    my $browser = $ua;
    my $nav_version = 0;
    my $browser_type = 'other';
    my $platform_type = 'other';
    my $indexer = 0;
    my $tstring;
    my $i = 0;
    my $plat = $ua;
    if ($ua =~ / WebTV\/(\S*) /) {
	$nav_version = $1;
	$browser = 'WebTV/' . $nav_version;
    } elsif ($ua =~ /^Opera\/(\S*)$/) {
	$nav_version = $1;
	$platform_type = 'Win32'; # Opera is Windows only
    } elsif ($ua =~ /^Safari\/(\S*)$/) { # I think this is wrong
	$nav_version = $1;
	$browser = 'Safari';
	$platform_type = 'OSX';	# Safari is OSX only
    } elsif ($ua =~ /^Mozilla.*Safari\/(\S*)$/) { # from developer.apple.com
	$nav_version = $1;
	$browser = 'Safari';
	$platform_type = 'OSX';	# Safari is OSX only
    } elsif ($ua =~ /^Konqueror\/(\S*)$/) {
	$nav_version = $1;
	$platform_type = 'Unix'; # Linux or FreeBSD
    } elsif ($ua =~ /StarOffice\/(\S*);(\S*)$/) { # lies, says it's Mozilla
	$nav_version = $1;
	$platform_type = $2;	# Linux or FreeBSD
    } elsif ($ua =~ /\(compatible; ([^;]*); (.*)\)/) {
	$browser = "$1; $2";	# special case, Microsoft says Mozilla
    } elsif ($ua =~ /\(compatible; (.*)\)/) {
	$browser = $1;		# special case, Microsoft
    } elsif ($ua =~ /\((Slurp[^ ]*) .*\)/) {
	$browser = $1;		# special case, Slurp
	$indexer = 1;
	$browser_type = 'indexer';
    } elsif ($ua =~ /^(Mozilla\/.*) \[.*\] \((.*)\)$/) {
	$browser = "$1; $2";	# Mozilla for Windows
	$plat = $2;
    } else {
	$cursor = index($browser, ' ');	# trim browser after space
	$browser = substr($browser, 0, $cursor) if $cursor > 1;
    }

    if (index($ua, 'Linux') >= 0) {
	$platform_type = 'Linux';
    } elsif (index($ua, 'Mac OS X') >= 0) {
	$platform_type = 'Mac';
    } elsif (index($ua, 'Mac_PowerPC') >= 0) {
	$platform_type = 'Mac';
    } elsif (index($ua, 'OS/2') >= 0) {
	$platform_type = 'OS/2';
    } elsif (index($ua, 'FreeBSD') >= 0) {
	$platform_type = 'Unix';
    } elsif (index($ua, 'SunOS') >= 0) {
	$platform_type = 'Unix';
    } elsif (index($ua, 'IRIX') >= 0) {
	$platform_type = 'Unix';
    } elsif (index($ua, 'X11') >= 0) {
	$platform_type = 'Unix';
    }

    $browser = substr($browser, 0, $max_browser_length) if length($browser) > $max_browser_length;
# See if this hit is from a web indexer, set $indexer to 1.
    for ($i=0; $i <= $main::nrobot; $i++) {
	$tstring = $main::robot[$i];
	if ($browser =~ /$tstring/i) {
	    $indexer = 1;
	    $browser_type = 'indexer';
	    last;
	}
    } # for
# See if this hit is from a web indexer's domain, set $indexer to 1.
    for ($i=0; $i <= $main::nrobotdom; $i++) {
	$tstring = $main::robotdom[$i];
	if ($dom =~ /$tstring/i) {
	    $indexer = 1;
	    $browser_type = 'indexer';
	    last;
	}
    } # for
# Classify browsers into major groups.
    if ($browser_type eq 'other') {
	for ($i = 0; $i<=$main::nbrowser_wars; $i++) {
	    $tstring = $main::wars[$i];
	    if ($browser =~ /$tstring/i) {
		$browser_type = $tstring;
		last;
	    }
	} # for
    } # if $browser_type
# Classify platforms into major groups.
    if ($platform_type eq 'other') {
	for ($i = 0; $i<=$main::nplatform_wars; $i++) {
	    $tstring = $main::platform_wars[$i];
	    if ($plat =~ /$tstring/i) {
		$platform_type = $tstring;
		$platform_type =~ s/Windows /Win/;
		last;
	    }
	} # for
    } # if $platform_type
    return ($browser, $indexer, $browser_type, $platform_type);

} # detect_browser

#----------------------------------------------------------------
# &print_heading_report ($today)
sub print_heading_report {
    my $thisdate = shift;
use strict;    

    if ($main::html) {
	open (REPORT, ">$main::output_file") or die "webtrax: Can't open $main::output_file";
	print REPORT "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">";
	print REPORT "<html><head>";
	print REPORT "<title>$main::site_name Access Statistics</title>\n";
	print REPORT "<meta name=\"robots\" content =\"noindex,nofollow\">\n";
	print REPORT "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">";
	if ($main::stylesheet ne '') {
	    print REPORT "<link rel=\"stylesheet\" type=\"text/css\" href=\"$main::stylesheet\">";
	} else {		# default internal style sheet
	    print REPORT "<style type=\"text/css\">\n";
	    print REPORT " dt {float: left}\n";
	    print REPORT " dd {margin-left: 40px}\n";
	    print REPORT " .navbar {font-size: 80%;}\n";
	    print REPORT " .chart {}\n";
	    print REPORT " .monthsum {}\n";
	    print REPORT " .analysis {}\n";
	    print REPORT " .brow {}\n";
	    print REPORT " .vc {}\n";
	    print REPORT " .sessd {}\n";
	    print REPORT " .pie {}\n";
	    print REPORT " .indexer {}\n";
	    print REPORT " .fnf {color: gray;}\n";
	    print REPORT " .cac {color: pink;}\n";
	    print REPORT " .fbd {color: green;}\n";
	    print REPORT " .filetype {font-size: 80%;}\n";
	    print REPORT " .illegal {}\n";
	    print REPORT " .refdom {font-weight: bold;}\n";
	    print REPORT " .newref {color: red;}\n";
	    print REPORT " .inred {color: red;}\n";
	    print REPORT " .max {color: red;}\n";
	    print REPORT " .min {color: blue;}\n";
	    print REPORT " .query {color: green;}\n";
	    print REPORT " .details {font-size: 80%;}\n";
	    print REPORT " td {padding-top: 0; padding-bottom: 0; margin-top: 0; margin-bottom: 0; border-top-width: 0; border-bottom-width: 0; line-height: 90%;}\n";
	    print REPORT " body {background-color: #ffffff; color: #000000;}\n";
	    print REPORT "</style>\n";
	}
	print REPORT "</head>\n";
	print REPORT "<body>\n";
	print REPORT "<h1>$main::site_name Access Statistics -- $thisdate</h1>\n\n";
	print REPORT "<a name=\"top\">&nbsp;</a>\n\n";
	&print_navbar();
	print REPORT "<p>\n\n";
	if ($main::preamble ne "") {
	    if (open (PREAM, $main::preamble)) {
		while (<PREAM>) {
		    print REPORT "$_";
		}
		close PREAM;
	    } else {
		print "webtrax: Can't open $main::preamble\n";
	    }
	} #if $preamble
	close REPORT;
    } else { 
	open (HEADER, ">$main::output_file") or die "webtrax: Can't open $main::output_file";
	$main::centered_body = "$main::site_name";
	write HEADER;
	$main::centered_body = "Web Access Report -- $thisdate";
	write HEADER;
	close HEADER;
    } # if $main::html
} #print_heading_report


#----------------------------------------------------------------
# &print_navbar
# REPORT is assumed open
sub print_navbar {
    print REPORT "<p><span class=\"navbar\">\n";
    print REPORT "<a href=\"$main::help_html\">Webtrax $main::version help</a>\n";
    print REPORT "| <a href=\"#top\">Top</a>\n";
    print REPORT "| <a href=\"#summary\">Summary</a>\n";
    print REPORT "| <a href=\"#analysis\">Analysis</a>\n";
    print REPORT "| <a href=\"#file\">File type</a>\n";
    print REPORT "| <a href=\"#illref\">Illegal</a>\n";
    print REPORT "| <a href=\"#accesstime\">Access time</a>\n";
    print REPORT "| <a href=\"#hits_tld\">TLD</a>\n";
    print REPORT "| <a href=\"#hits_domain\">Domain</a>\n";
    print REPORT "| <a href=\"#cumpage\">Year page</a>\n";
    print REPORT "| <a href=\"#year_tld\">Year TLD</a>\n";
    print REPORT "| <a href=\"#class\">Class</a>\n";
    print REPORT "| <a href=\"#browser\">Browser</a>\n";
    print REPORT "| <a href=\"#query\">Query</a>\n";
    print REPORT "| <a href=\"#referrer\">Referrer</a>\n";
    print REPORT "| <a href=\"#year_referrer\">Year referrer</a>\n";
    print REPORT "| <a href=\"#engine\">Engine</a>\n";
    print REPORT "| <a href=\"#retcode\">Retcode</a>\n";
    print REPORT "| <a href=\"#verb\">Verb</a>\n";
    print REPORT "| <a href=\"#details\">Details</a>\n";
    print REPORT "| Return to <a href=\"$main::return_URL\">$main::site_name</a>\n";
    print REPORT "</span>\n";
} #print_navbar

#----------------------------------------------------------------
# &print_month_summary_report ($day_lines)
sub print_month_summary_report {
    my ($day_lines, $monthrpt_date1_ref, $monthrpt_date2_ref, 
	$monthrpt_visits_ref, $monthrpt_mb_ref, $monthrpt_hits_ref, $monthrpt_pages_ref,
	$min_day_visits, $min_day_mb, $min_day_hits, $min_day_pages,
	$max_day_visits, $max_day_mb, $max_day_hits, $max_day_pages,
	$month_visits, $month_mb, $month_hits, $month_pages, $days_with_html_pages) = @_;
    my ($daylinesx, $x1, $x2, $x3, $x4, $x5, $x6);
use strict;    
    
    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for appending";
    &print_h2 ("Summary:", "summary");
    if ($main::html) {
		print REPORT "<div class=\"monthsum\">\n";
		print REPORT "<table cellspacing=\"7\" summary=\"\">\n";
		print REPORT "<tr><th>From</th><th>To</th><th><a href=\"$main::help_html#visit\">Visits</a></th><th>Mb</th><th><a href=\"$main::help_html#hit\">Hits</a></th><th><a href=\"$main::help_html#page\">Pages</a></th></tr>\n";
	} else {
		print REPORT "      From                To          Visits    Mb     Hits    Pages\n";
		print REPORT "=================  =================  ======  ======  ======  ======\n";
    } # if $main::html
    
    $daylinesx = 0;
    while ($daylinesx < $day_lines) {
		$x1 = &intfmt($$monthrpt_visits_ref[$daylinesx], 6);
		$x2 = &intfmt($$monthrpt_mb_ref[$daylinesx], 6);
		$x3 = &intfmt($$monthrpt_hits_ref[$daylinesx], 6);
		$x4 = &intfmt($$monthrpt_pages_ref[$daylinesx], 6);
		$x5 = $$monthrpt_date1_ref[$daylinesx];
		$x6 = $$monthrpt_date2_ref[$daylinesx];
		if ($main::html) {
		    $x1 = "<span class=\"min\">$x1</span>" if $$monthrpt_visits_ref[$daylinesx] eq $min_day_visits;
		    $x2 = "<span class=\"min\">$x2</span>" if $$monthrpt_mb_ref[$daylinesx] eq $min_day_mb;
		    $x3 = "<span class=\"min\">$x3</span>" if $$monthrpt_hits_ref[$daylinesx] eq $min_day_hits;
		    $x4 = "<span class=\"min\">$x4</span>" if $$monthrpt_pages_ref[$daylinesx] eq $min_day_pages;
		    $x1 = "<span class=\"max\">$x1</span>" if $$monthrpt_visits_ref[$daylinesx] eq $max_day_visits;
		    $x2 = "<span class=\"max\">$x2</span>" if $$monthrpt_mb_ref[$daylinesx] eq $max_day_mb;
		    $x3 = "<span class=\"max\">$x3</span>" if $$monthrpt_hits_ref[$daylinesx] eq $max_day_hits;
		    $x4 = "<span class=\"max\">$x4</span>" if $$monthrpt_pages_ref[$daylinesx] eq $max_day_pages;
		    print REPORT "<tr><td>$x5</td><td>$x6</td><td align=right>$x1</td><td align=right>$x2</td><td align=right>$x3</td><td align=right>$x4</td></tr>\n";
		} else {
		    print REPORT "$x5  $x6  $x1  $x2  $x3  $x4\n";
		} # if $main::html
		++$daylinesx;
    } # while $daylinesx
    if ($day_lines>0) {	# compute some averages and print them out
		$x1 = &intfmt($day_lines, 3);
		$x2 = &intfmt(int($month_visits/$day_lines), 6); # ?? compute field width
		$x3 = &intfmt(int($month_mb/$day_lines), 6);
		$x4 = &intfmt(int($month_hits/$day_lines), 6);
		$x5 = &intfmt(int($month_pages/$days_with_html_pages), 6); # note different denominator
		if ($main::html) {
		    print REPORT "<tr><th>$x1 days</th><th align=right>Avg</th><th align=right>$x2</th><th align=right>$x3</th><th align=right>$x4</th><th align=right>$x5</th></tr>\n";
		    print REPORT "</table>\n";
		    print REPORT "</div>\n";
		} else {
		    print REPORT "=================  =================  ======  ======  ======  ======\n";
		    print REPORT "                   $x1 days      Avg  $x2  $x3  $x4  $x5\n";
		} # if $main::html
    } # compute some averages and print them out
    close REPORT;
} # print_month_summary_report

#----------------------------------------------------------------
# &print_analysis_report($start_time, 
# 		       $end_time,
# 		       \%day_hits_by_file_type, 
# 		       \%day_hits_by_hittype, 
# 		       \%day_visits_by_hittype, 
# 		       \%day_visits_by_class,
# 		       \%day_visits_by_browser_war, 
# 		       \%day_visits_by_platform_war, 
# 		       \%day_html_hits_by_page,
# 		       $day_hits_total, 
# 		       $day_visits_total, 
# 		       $day_hits_by_class_total, 
# 		       $nbrowser_wars, 
# 		       $nplatform_wars, 
# 		       $nengines, 
# 		       $nrobot,
# 		       $day_html_hits_total, 
#                      $day_nohtml_visits,
#                      $day_nohtml_hits,
# 		       $nheadpage);
# print the hit and visit analysis

sub print_analysis_report {
    my ($start_time, $end_time,
	$day_hits_by_file_type_ref, $day_hits_by_hittype_ref, 
	$day_visits_by_hittype_ref, $day_visits_by_class_ref,
	$day_visits_by_browser_war_ref, $day_visits_by_platform_war_ref, 
	$day_html_hits_by_page_ref,
	$day_hits_total, $day_visits_total, $day_hits_by_class_total, 
	$nbrowser_wars, $nplatform_wars, $nengines, $nrobot,
	$day_html_hits_total, $day_nohtml_visits, $day_nohtml_hits, $nheadpage) = @_;
    my ($other_visits, $xx, $distinct);
use strict;    
    
    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for appending";
    &print_h2 ("Analysis for this period: $start_time to $end_time", "analysis");
    
# todo: save this and show stacked bar graphs for a whole month
    print REPORT "<div class=\"pie\">\n" if $main::html;
    &print_pie_chart ($day_hits_by_file_type_ref, "$day_hits_total Hits by file type");
    &print_pie_chart ($day_visits_by_hittype_ref, "$day_visits_total Visits by source");
    if ($day_hits_by_class_total > 0) {
	&print_pie_chart ($day_visits_by_class_ref, "$day_visits_total Visits by subject");
    }
    if ($nbrowser_wars > 0) {
	&print_pie_chart ($day_visits_by_browser_war_ref, "$day_visits_total Visits by browser class");
    }
    if ($nplatform_wars > 0) {
	&print_pie_chart ($day_visits_by_platform_war_ref, "$day_visits_total Visits by platform");
    }
    # almost all hits and MB are on "local" references.  Could show this, or skip them
    # $temp = int ($day_mb_total);
    # &print_pie_chart (\%day_size_by_hittype, "$temp MB");
    # &print_pie_chart (\%day_hits_by_hittype, "$day_hits_total Hits");
    print REPORT "</div>\n" if $main::html;
    print REPORT "<div class=\"analysis\"><table summary=\"$start_time to $end_time\">\n" if $main::html;

# total hits vs html hits
    $distinct = 0;
    foreach (keys (%$day_html_hits_by_page_ref)) {
	$distinct++;
    }
    print REPORT "<tr><td>" if $main::html;
    print REPORT "$distinct ";
    print REPORT "<a href=\"$main::help_html#page\">" if $main::html;
    print REPORT "HTML pages";
    print REPORT "</a></td><td align=right>" if $main::html;
    &print_analysis2 ($day_html_hits_total, $day_hits_total, "hits");
    print REPORT "</td><td align=right>" if $main::html;
    &print_analysis2 ($day_visits_total-$day_nohtml_visits, $day_visits_total, "visits");
    print REPORT "</td></tr>" if $main::html;
    print REPORT "\n";
    
# head page report
    if ($nheadpage >= 0) {
	print REPORT "<tr><td>" if $main::html;
	$xx = $nheadpage+1;
	print REPORT "$xx ";
	print REPORT "<a href=\"$main::help_html#head\">" if $main::html;
	print REPORT "Head pages";
	print REPORT "</a></td><td align=right>" if $main::html;
	&print_analysis2 ($$day_hits_by_hittype_ref{'search+hp'}+
			  $$day_hits_by_hittype_ref{'link+hp'}+
			  $$day_hits_by_hittype_ref{'hp'}, 
			  $day_hits_total, "hits");
	print REPORT "</td><td align=right>" if $main::html;
	&print_analysis2 ($$day_visits_by_hittype_ref{'search+hp'}+
			  $$day_visits_by_hittype_ref{'link+hp'}+
			  $$day_visits_by_hittype_ref{'hp'}, 
			  $day_visits_total, "visits");
	print REPORT "</td></tr>" if $main::html;
	print REPORT "\n";
    } # if $nheadpage
    
# search engine report
    if ($nengines >= 0) {
	print REPORT "<tr><td>" if $main::html;
	$xx = $nengines+1;
	print REPORT "$xx ";
	print REPORT "<a href=\"$main::help_html#engine\">" if $main::html;
	print REPORT "Search engines";
	print REPORT "</a></td><td align=right>" if $main::html;
	&print_analysis2 ($$day_hits_by_hittype_ref{'search+hp'}+
			  $$day_hits_by_hittype_ref{'search'},
			  $day_hits_total, "hits");
	print REPORT "</td><td align=right>" if $main::html;
	&print_analysis2 ($$day_visits_by_hittype_ref{'search+hp'}+
			  $$day_visits_by_hittype_ref{'search'}, 
			  $day_visits_total, "visits");
	print REPORT "</td></tr>" if $main::html;
	print REPORT "\n";
    } # if $nengines
    
# parasite report
    if ($day_nohtml_visits >= 0) {
	print REPORT "<tr><td>" if $main::html;
	print REPORT "<a href=\"$main::help_html#indexer\">" if $main::html;
	print REPORT "Visits without any HTML";
	print REPORT "</a></td><td align=right>" if $main::html;
	&print_analysis2 ($day_nohtml_hits, $day_hits_total, "hits");
	print REPORT "</td><td align=right>" if $main::html;
	&print_analysis2 ($day_nohtml_visits, $day_visits_total, "visits");
	print REPORT "</td></tr>" if $main::html;
	print REPORT "\n";
    } # if $day_nohtml_visits

# web indexer report
    if ($nrobot >= 0) {
	print REPORT "<tr><td>" if $main::html;
	$xx = $nrobot+1;
	print REPORT "$xx ";
	print REPORT "<a href=\"$main::help_html#indexer\">" if $main::html;
	print REPORT "Web indexers";
	print REPORT "</a></td><td align=right>" if $main::html;
	&print_analysis2 ($$day_hits_by_hittype_ref{'indexer'}, 
			  $day_hits_total, "hits");
	print REPORT "</td></tr>" if $main::html;
	print REPORT "\n";
    } # if $nrobot
    
# direct links report
    print REPORT "<tr><td>" if $main::html;
    $xx = $$day_hits_by_hittype_ref{'link'}+$$day_hits_by_hittype_ref{'link+hp'};
    print REPORT "$xx ";
    print REPORT "<a href=\"$main::help_html#link\">" if $main::html;
    print REPORT "Links";
    print REPORT "</a></td><td align=right>" if $main::html;
    &print_analysis2 ($$day_hits_by_hittype_ref{'link'}+
		      $$day_hits_by_hittype_ref{'link+hp'},
		      $day_hits_total, "hits");
    print REPORT "</td><td align=right>" if $main::html;
    &print_analysis2 ($$day_visits_by_hittype_ref{'link+hp'}+
		      $$day_visits_by_hittype_ref{'link'}, 
		      $day_visits_total, "visits");
    print REPORT "</td></tr>" if $main::html;
    print REPORT "\n";
    print REPORT "</table></div>\n" if $main::html;
    close REPORT;
} # print_month_summary_report
# ................................................................
# &print_analysis2 ($kind, $total, $units)
# sub-subroutine to write one line on the report
sub print_analysis2 {
    my $x2 = shift;
    my $x3 = shift;
    my $x4 = shift;
    my $n0;
    my $n1;
    my $n3;
    my $n4;
use strict;    

    $x3 = 1 if $x3 == 0;	# don't div by zero

    $n0 = &fldw($x3);
    $n1 = &intfmt($x2, $n0);
    $n4 = int($x2*100.0/$x3);
    $n3 = &intfmt($n4, 3);
    print REPORT "  $n1 $x4 ($n3%)";
} # print_analysis2

#----------------------------------------------------------------
# &print_html_pages_report(\%day_html_hits_by_page, 
# 			 \%day_hits_caused_by_page, 
# 			 \%day_size_caused_by_page,
# 			 \%day_html_hits_by_page_by_hittype,
# 			 $nshowpages);
# Special report for pages, giving histogram
sub print_html_pages_report {
    my ($day_html_hits_by_page_ref, $day_hits_caused_by_page_ref, $day_size_caused_by_page_ref,
	$day_html_hits_by_page_by_hittype_ref, $nshowpages) = @_;
    my ($biggest, $longest, $biggest2, $biggest3, $hourx, $title, $factor);
    my ($page, $n, $nx, $bar, $barn, $x1, $x2, $x3, $x4, $gif, $distinct);
    my @sortedkeys;
use strict;    

    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for appending";
    &print_h2("This Period's Accesses by File Type:", "file");

    @sortedkeys = sort comp1 keys(%$day_html_hits_by_page_ref);
    sub comp1 {
no strict;
	($$day_html_hits_by_page_ref{$b} <=> $$day_html_hits_by_page_ref{$a}) || ($a cmp $b);
    }
    $biggest = 0;
    $longest = 0;
    $biggest2 = 0;
    $biggest3 = 0;
    $distinct = 0;
    foreach (@sortedkeys) {
	$biggest = $$day_html_hits_by_page_ref{$_} if $$day_html_hits_by_page_ref{$_} > $biggest;
	$biggest3 = $$day_hits_caused_by_page_ref{$_} if $$day_hits_caused_by_page_ref{$_} > $biggest3;
	$biggest2 = int($$day_size_caused_by_page_ref{$_}/1024) if int($$day_size_caused_by_page_ref{$_}/1024) > $biggest2;
	$longest = length ($_) if length ($_) > $longest;
	$distinct++;
    } # foreach
    $factor = 1;
    if ($biggest > $main::nhhw) {
	$factor = int($biggest/$main::nhhw) + 1;
    }
    $title = "$distinct Pages (*.$main::html_types) hits caused, KB caused, hits on page";
    $title .= ", top $nshowpages" unless $nshowpages > 1000;
    $title .= " (each * represents $factor hits)" unless ($factor == 1 || $main::html == 1);
    &print_h2 ($title, "");
    &print_legend ("LEGEND: ") if $main::html;

    $nx = $nshowpages-1;
    foreach (@sortedkeys) {
	$page = $_;
	$n = $$day_html_hits_by_page_ref{$page};
	$barn = int($n/$factor);
	$x1 = &prettypagename($page, $longest); # won't get things with dirname match
	$x2 = &intfmt ($$day_hits_caused_by_page_ref{$page}, &fldw($biggest3));
	$x3 = &intfmt (int($$day_size_caused_by_page_ref{$page}/1024), &fldw($biggest2)); #KB
	$x4 = &intfmt ($n, &fldw($biggest)); #hits
	if ($main::html) {
	    $barn *= $main::hbw;
	    print REPORT "<tr><td>$x1</td><td align=right>$x2&nbsp;</td><td align=right>$x3&nbsp;</td><td align=right>$x4</td><td>";
	    #print REPORT "<img src=\"redpix.gif\" alt=\"\" width=$barn height=$main::hbh>" if $barn > 0;
	    if ($barn > 0) {
		for (@main::hittype_names) {
		    $gif = $main::gifnames{$_};
		    $n = $$day_html_hits_by_page_by_hittype_ref{$page}{$_};
		    $barn = int($n/$factor);
		    $barn *= $main::hbw;
		    print REPORT "<img src=\"$gif\" alt=\"\" width=$barn height=$main::hbh>" if $barn > 0;
		} # for
	    } # if $barn
	    print REPORT "</td></tr>\n";
	} else {
	    $bar = '*' x $barn;
	    print REPORT "$x1  $x2  $x3  $x4  $bar\n";
	}
	last if $nx-- <= 0;
    } # foreach
    print REPORT "</table></div>" if $main::html;
    print REPORT "\n";
    close REPORT;
} # print_html_pages_report

#----------------------------------------------------------------
# &prettypagename($name, $longest)
# handles making it red and hotlinking
sub prettypagename {
    my $page = shift;
    my $longest = shift;
    my $class = '';
    my $rv;
    my $i;

    if ($main::html) {
 	for ($i = 0; $i<=$main::ninred; $i++) {
 	    if ($page =~ /$main::inred[$i]/) {
 		$class = $main::inredclass[$i];
 	    }
 	} # for
	$rv = "";
	if ($main::hotlink_html_prefix ne '-') {
	    $rv .= "<a href=\"";
	    $rv .= $main::hotlink_html_prefix;
	    $rv .= &escapeHtml($page);
	    $rv .= "\" rel=\"nofollow\">";
	    $rv .= "<span class=\"$class\">" if $class ne '';
	    $rv .= &escapeHtml($page);
	    $rv .= "</span>" if $class ne '';
	    $rv .= "</a>";
	} else {
	    $rv .= "<span class=\"$class\">" if $class ne '';
	    $rv .= &escapeHtml($page);
	    $rv .= "</span>" if $class ne '';
	}
	$rv .= '&nbsp;';
    } else {
	$rv = &padwidth ($page, $longest);
    }
    return $rv;
} #prettypagename

#----------------------------------------------------------------
# &print_filetype_report (\counter_array, $title)
sub print_filetype_report {
    my $counter_array_ref = shift;
    my $rpttitle = shift;
    my @sortedkeys;
    my ($filename);
use strict;    

    my $n = scalar keys(%$counter_array_ref);
    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for appending";
    if ($main::html) {
	print REPORT "<h3>$n $rpttitle</h3>\n\n<div class=\"filetype\">\n";
    } else {
	print REPORT "$n $rpttitle\n--------------\n";
    }
    close REPORT;
    @sortedkeys = sort comparer keys(%$counter_array_ref);
    sub comparer {
no strict;
        ($$counter_array_ref{$b} <=> $$counter_array_ref{$a}) || ($a cmp $b);
    }
    $main::totals_body = '';
    foreach (@sortedkeys) {
	if ($main::html) {
	    $filename = &escapeHtml($_);
	} else {
	    $filename = $_;
	}
	$main::totals_body .= "$filename $$counter_array_ref{$_}, ";
    } # foreach
    chop($main::totals_body); # clean off the trailing space
    chop($main::totals_body); # and the trailing comma
    if ($main::totals_body eq '') { 
	$main::totals_body = "No files accessed"; 
    }
    open (TOTALS, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for TOTALS";
    write TOTALS; # writes $totals_body, formatted into multiple lines
    close TOTALS;
    if ($main::html) {
	open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file for appending";
	print REPORT "</div>\n";
	close REPORT;
    }
} # print_filetype_report

#----------------------------------------------------------------
# &print_illref_report(\%day_hits_illref, \%day_size_illref, $day_hits_illref_total)
# print the illegal_reference report
sub print_illref_report {
    my ($day_hits_illref_ref, $day_size_illref_ref, $day_hits_illref_total) = @_;
    my ($x1, $x2, $x3, $line, $x1a, $x1b);
    my @sortedkeys;
use strict;    

    open (REPORT, ">>$main::output_file") or
        die "webtrax: Can't open $main::output_file for appending"; # appending now
    &print_h2 ("$day_hits_illref_total <a href=\"$main::help_html#illegal\">illegal referrers</a>: hits, KB, referrer", "illref");
    @sortedkeys = sort cmp_ill keys(%$day_hits_illref_ref);
    sub cmp_ill { 
no strict;
        ($$day_hits_illref_ref{$b} <=> $$day_hits_illref_ref{$a}) || ($a cmp $b);
    }
    print REPORT "<div class=\"chart\"><table summary=\"illegal\">\n" if $main::html;
    foreach (@sortedkeys) {
	$x1 = $_;		# referring site ... referred object
	if ($x1 =~ /^(.*) \.\.\. (.*)$/) { # extract the referring site
	    $x1a = $1;
	    $x1b = $2;
	} else {
	    $x1a = $x1;
	    $x1b = '';
	}
	$x2 = &intfmt($$day_hits_illref_ref{$_}, 6);
	$x3 = &intfmt(int($$day_size_illref_ref{$_}/1024), 6);
	if ($main::html) {
	    $line = "<tr><td align=right>$x2&nbsp;&nbsp;</td><td align=right>$x3&nbsp;&nbsp;</td><td><a href=\"";
	    $line .= &escapeHtml($x1a);
	    $line .= "\" rel=\"nofollow\">";
	    $line .= &escapeHtml($x1a);
	    $line .= "</a></td><td>&nbsp;";
	    $line .= &escapeHtml($x1b);
	    $line .= "</td></tr>";
	    print REPORT "$line\n";
	} else {
	    print REPORT "$x2 $x3  $x1\n";
	}
    } #foreach
    print REPORT "</table></div>\n" if $main::html;
    close REPORT;
} #print_illref_report

#----------------------------------------------------------------
# &print_accesstime_report(\%hits, \%visits, \%size, \%visits_by_hittype)
# print the access time histogram
sub print_accesstime_report {
    my (
	$day_hits_by_hour_ref, $day_visits_by_hour_ref, $day_size_by_hour_ref, 
	$day_visits_by_hour_by_hittype_ref) = @_;
    my ($biggest1, $biggest2, $biggest3, $hourx, $title, $factor, $bar, $barn, $x1, $x2, $x3, $x4, $gif);
use strict;    

    open (REPORT, ">>$main::output_file") or
        die "webtrax: Can't open $main::output_file for appending"; # appending now
    $biggest1 = 0;
    $biggest2 = 0;
    $biggest3 = 0;
    foreach $hourx (0 .. 23) {
	$biggest1 = $$day_visits_by_hour_ref[$hourx] if $$day_visits_by_hour_ref[$hourx] > $biggest1;
	$biggest2 = $$day_hits_by_hour_ref[$hourx] if $$day_hits_by_hour_ref[$hourx] > $biggest2;
	$biggest3 = $$day_size_by_hour_ref[$hourx] if $$day_size_by_hour_ref[$hourx] > $biggest3;
    }
    $factor = 1;
    $biggest3 = $biggest3 / 1024; # field width of KB column
    if ($biggest1 > $main::nhhw) {	# scale the stars on the visit column
	$factor = int($biggest1/$main::nhhw) + 1;
    }
    $title = "This Period's hits, KB, visits by hour";
    $title .= " (each * represents $factor visits)" unless ($factor == 1 || $main::html == 1);
    &print_h2 ($title, "accesstime");
    &print_legend ("LEGEND: ") if $main::html;

    foreach $hourx (0 .. 23) {
        $barn = int($$day_visits_by_hour_ref[$hourx]/$factor);
	$x1 = &twodigit ($hourx);
	$x2 = &intfmt ($$day_visits_by_hour_ref[$hourx], &fldw($biggest1));
	$x3 = &intfmt ($$day_hits_by_hour_ref[$hourx], &fldw($biggest2));
	$x4 = &intfmt (int($$day_size_by_hour_ref[$hourx]/1024), &fldw($biggest3));
	if ($main::html) {
	    $barn *= $main::hbw;
	    print REPORT "<tr><td>$x1:00&nbsp;</td><td align=right>$x3&nbsp;</td><td align=right>$x4&nbsp;</td><td align=right>$x2&nbsp;</td><td>";
	    if ($barn > 0) {
		for (@main::hittype_names) {
		    $gif = $main::gifnames{$_};
		    $barn = int($$day_visits_by_hour_by_hittype_ref[$hourx]{$_}/$factor);
		    $barn *= $main::hbw;
		    print REPORT "<img src=\"$gif\" alt=\"\" width=$barn height=$main::hbh>" if $barn > 0;
		} # for
	    } # if $barn
	    print REPORT "</td></tr>\n";
	} else {
	    $bar = '*' x $barn;
    	    print REPORT "$x1:00  $x3  $x4  $x2  $bar\n";
	}
    } # foreach
    print REPORT "</table></div>\n" if $main::html;
    close REPORT;
} # print_accesstime_report

#----------------------------------------------------------------
# &print_cumpage_report (\%year_hits_by_file, $year_hits_total, $nshow, $nocumpage_extensions, $year_page_reset)
# report cumulative  hits per page
sub print_cumpage_report {
    my ($year_hits_by_file_ref, $year_hits_total, $nshowbusycumpages, $nocumpage_extensions, $year_page_reset) = @_;
    my ($x1, $x2, $biggest, $longest, $nx, $factor, $title, $n, $bar, $barn);
    my @sortedkeys;
use strict;    

    open (REPORT, ">>$main::output_file") or 
        die "webtrax: Can't open $main::output_file for appending";
    $biggest = 0;
    $longest = 0;
    $nx = $nshowbusycumpages - 1;
    @sortedkeys = sort cmp_cum_hits keys(%$year_hits_by_file_ref);
    sub cmp_cum_hits {
no strict;
        ($$year_hits_by_file_ref{$b} <=> $$year_hits_by_file_ref{$a}) || ($a cmp $b);
    }
    foreach (@sortedkeys) {
	next if /$nocumpage_extensions/io; # don't display gif/jpg
	$biggest = $$year_hits_by_file_ref{$_} if $$year_hits_by_file_ref{$_} > $biggest;
	$longest = length ($_) if length ($_) > $longest;
	last if $nx-- <= 0;
    }
    $factor = 1;
    if ($biggest > $main::nhhw) {
	$factor = int($biggest/$main::nhhw) + 1;
    }
    $title = "\n$year_hits_total Cumulative hits by page since $year_page_reset";
    $title .= ", top $nshowbusycumpages pages" unless $nshowbusycumpages > 1000;
    $title .= " (each * represents $factor hits)" unless ($factor == 1 || $main::html == 1);
    &print_h2 ($title, "cumpage");
    print REPORT "<div class=\"chart\"><table summary=\"cumulative hits\">\n" if $main::html;

    $nx = $nshowbusycumpages - 1;
    foreach (@sortedkeys) {
	next if /$nocumpage_extensions/io; # don't display gif/jpg
	$n = $$year_hits_by_file_ref{$_};
	$barn = int($n/$factor);
	$x1 = &prettypagename($_, $longest);
	$x2 = &intfmt ($n, &fldw($biggest));
	if ($main::html) {
	    $barn *= $main::hbw;
	    print REPORT "<tr><td>$x1</td><td align=right>$x2&nbsp;</td><td>";
	    print REPORT "<img src=\"redpix.gif\" alt=\"\" width=$barn height=$main::hbh>" if $barn > 0;
	    print REPORT "</td></tr>\n";
	} else {
	    $bar = '*' x $barn;
	    print REPORT "$x1  $x2  $bar\n";
	} # if $main::html
	last if $nx-- <= 0;
    } # foreach
    print REPORT "</table></div>" if $main::html;
    close REPORT;
} # print_cumpage_report

#----------------------------------------------------------------
# &print_retcode_report (\%day_hits_by_retcode, \%day_size_by_retcode, $day_rec_total, $day_rec_size)
# Print the error code analysis
sub print_retcode_report {
    my ($day_hits_by_retcode_ref, $day_size_by_retcode_ref, $day_rec_total, $day_rec_size) = @_;
    my ($x1, $x2, $x3, $x4);
use strict;    

    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file";
    &print_h2 ("Summary by server return code: Transactions, KB this period", "retcode");
    $x1 = &intfmt($day_rec_total, 6);
    $x2 = &intfmt(int($day_rec_size/1024), 8);
    if ($main::html) {
        print REPORT "<div class=\"chart\"><table summary=\"retcode\">\n";
		print REPORT "<tr><th align=right>$x1&nbsp;</th><th align=right>$x2&nbsp;</th><th>Code</th><th></th></tr>\n";
	} else {
		print REPORT "$x1 $x2 Code\n-----------------\n";
	}
	foreach (keys %$day_hits_by_retcode_ref) {
		$x1 = &intfmt($$day_hits_by_retcode_ref{$_}, 6);
		$x2 = &intfmt(int($$day_size_by_retcode_ref{$_}/1024), 8);
		$x3 = $_;
		$x4 = $main::retname{$_};
		if ($main::html) {
			print REPORT "<tr><td align=right>$x1&nbsp;</td><td align=right>$x2&nbsp;</td><td align=right>$x3&nbsp;</td><td>$x4</td></tr>\n";
		} else {
			print REPORT "$x1 $x2  $x3 $x4\n";
		}
	} #foreach
    if ($main::html) {
        print REPORT "</table></div>\n";
    }
    close REPORT;
} # print_retcode_report

#----------------------------------------------------------------
# &print_verb_report (\%day_hits_by_verb, \%day_size_by_verb, $day_rec_total, $day_rec_size)
# Print the transaction verb analysis, ie HEAD, GET, POST
sub print_verb_report {
    my ($day_hits_by_verb_ref, $day_size_by_verb_ref, $day_rec_total, $day_rec_size) = @_;
    my ($x1, $x2, $x3);
use strict;    

    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file";
    &print_h2 ("Summary by protocol verb: Log records, KB this period", "verb");
    $x1 = &intfmt($day_rec_total, 6);
    $x2 = &intfmt(int($day_rec_size/1024), 8);
    if ($main::html) {
        print REPORT "<div class=\"chart\"><table summary=\"verb\">\n";
	print REPORT "<tr><th align=right>$x1&nbsp;</th><th align=right>$x2&nbsp;</th><th>Verb</th></tr>\n";
    } else {
	print REPORT "$x1 $x2 Code\n-----------------\n";
    }
    foreach (keys %$day_hits_by_verb_ref) {
	$x1 = &intfmt($$day_hits_by_verb_ref{$_}, 6);
	$x2 = &intfmt(int($$day_size_by_verb_ref{$_}/1024), 8);
	$x3 = $_;
	if ($main::html) {
	    print REPORT "<tr><td align=right>$x1&nbsp;</td><td align=right>$x2&nbsp;</td><td>$x3</td></tr>\n";
	} else {
	    print REPORT "$x1 $x2  $x3\n";
	}
    } #foreach
    if ($main::html) {
        print REPORT "</table></div>\n";
    }
    close REPORT;
} # print_verb_report

#----------------------------------------------------------------
# &print_visit_details_report ()
# Print out the visit details, stored in a separate disk file.
# If not in HTML mode, uses the format statement DETAILS to make the formatting pretty.

# This is where we would change to support spilling the details list to disk if too big.

sub print_visit_details_report {
    use strict;    

    open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file";
    my $rem = ":";
    $rem = " (>= $main::min_details_session pages):" if $main::min_details_session > 1;
    &print_h2 ("This Period's <a href=\"$main::help_html#detail\">Visit Details</a>$rem", "details");
    if ($main::html) {
	print REPORT "<div class=\"details\">\n<dl compact>\n";
    } else {
	close REPORT;		# Write to same file but with a format stmt.
	open (DETAILS, ">>$main::output_file") or die "webtrax: Can't open $main::output_file";
    }
    close DETAILTEMPOUT;
    open (DETAILTEMPIN, "$main::detail_temp_file") || die "can't reopen $main::detail_temp_file";
    while (<DETAILTEMPIN>) {
	chomp;
	if ($main::html) {
	    print REPORT "$_\n";
	} else {
	    $main::details_body = $_;
	    write DETAILS;
	}
    } # foreach
    close DETAILTEMPIN;
    unlink $main::detail_temp_file;
    if ($main::html) {
	print REPORT "</dl>\n";
	print REPORT "</div>\n";
	close REPORT;
    } else {
	close DETAILS;
    }
} # print_visit_details_report

#----------------------------------------------------------------
# &print_tail_report ()
# Print out the end of the report, if any
sub print_tail_report {
use strict;    

    if ($main::html) {
		open (REPORT, ">>$main::output_file") or die "webtrax: Can't open $main::output_file";
		if ($main::postamble ne "") {
		    if (open (POST, $main::postamble)) {  
			while (<POST>) {
			    print REPORT "$_";
			}
			close POST;
		    } else {
			print "webtrax: Can't open $main::postamble\n";
		    }
		} # if postamble
		print REPORT "\n\n<hr>\n\n";
		&print_navbar();
		print REPORT "</body>\n</html>\n";
		close REPORT;
		unless (chmod(0644, $main::output_file)) {
		    print "webtrax: Couldn't chmod $main::output_file\n";
		}
	} # if $main::html
} # print_tail_report

#----------------------------------------------------------------
# When I changed this code to pass references instead of typeglobs, it stopped working.
# The first call to &print_histogram_report worked fine.  Second and later calls did not
# sort the rows correctly.  I think there is a bug in Perl's peculiar calling sequence
# to sort-comparison routines.  That's why this routine mixes typeglobs and references.

# &print_histogram_report (*counthits, \%countvisits, \%countsize, \$max, $title, $cutoff, $datename, $tag)
# given three arrays, print a histogram report
sub print_histogram_report {
    local *histo_hit = shift;
    my $histo_visits_ref = shift;
    my $histo_size_ref = shift;
    my $reptitle = shift;
    my $n_to_print = shift;
    my $period = shift;
    my $tag = shift;
    my $maxkeylth = shift;

    my ($factor, $biggest, $widest);
#    my $biggest2;
#    my $biggest3;
    my @sortedkeys;
    my ($n, $barn, $bar, $x1, $x2, $x3, $x4, $nx, $title);
    my $count;
    my ($graph_visits, $graph_hits, $graph_size);
use strict;    
    
    open (REPORT, ">>$main::output_file") or 
	die "webtrax: Can't open $main::output_file for appending";
    $graph_visits = 0;
    $graph_hits = 0;
    $graph_size = 0;
    $widest = 0;
    $biggest = 0;
#    $biggest2 = 0;
#    $biggest3 = 0;
    $nx = $n_to_print -1;
    $count = 0;
    @sortedkeys = sort cmp2 keys(%main::histo_hit);
    sub cmp2 {
no strict;
        ($main::histo_hit{$b} <=> $main::histo_hit{$a}) || ($a cmp $b);
    }
    foreach (@sortedkeys) {
	if ($nx-- >= 0) {
	    $biggest = $main::histo_hit{$_} if $main::histo_hit{$_} > $biggest;
#    	    $biggest2 = $$histo_size_ref{$_} if $$histo_size_ref{$_} > $biggest2;
#    	    $biggest3 = $$histo_visits_ref{$_} if $$histo_visits_ref{$_} > $biggest3;
            $graph_hits += $main::histo_hit{$_};
	    $graph_size += $$histo_size_ref{$_};
	    $graph_visits += $$histo_visits_ref{$_};
	    $widest = length($_) if length($_) > $widest;
	} # if $nx
	$count++; # still count it so heading is right
    } # foreach
    $factor = 1;
    $graph_size = int($graph_size / 1024);
    if ($biggest > $main::nhhw) {
	$factor = int($biggest/$main::nhhw) + 1;
    }
    $title = "\n$count $reptitle: Visits, KB, Hits $period";
    $title .= " (top $n_to_print)" if $n_to_print < 1000;
    $title .= " (each * represents $factor hits)" unless ($factor == 1 || $main::html == 1);
    &print_h2 ($title, $tag);

    $x1 = &padwidth(" TOTAL", $widest);
    $x3 = &intfmt($graph_size, &fldw($graph_size));
    $x4 = &intfmt($graph_visits, &fldw($graph_visits));
    $x2 = &intfmt($graph_hits, &fldw($graph_hits));
    if ($main::html) {
        print REPORT "<div class=\"chart\"><table summary=\"$reptitle\">\n";
        print REPORT "<tr><th align=right>$x1&nbsp;</th><th align=right>$x4</th><th align=right>&nbsp;$x3</th><th align=right>&nbsp;$x2</th></tr>\n";
    } else {
        print REPORT "$x1  $x4  $x3  $x2\n--------------------------\n";
    }
    $widest = $maxkeylth if $widest > $maxkeylth;
    $nx = $n_to_print -1;
    foreach (@sortedkeys) {
	$n = $main::histo_hit{$_};
	$barn = int($n/$factor);
	$x1 = $_;
	$x1 = substr($x1, 0, $maxkeylth) if length($x1) > $maxkeylth;
	if ($main::html) {
	    $x1 = &escapeHtml($x1);
	} else {
	    $x1 = &padwidth ($x1, $widest);
	}
	$x3 = &intfmt (int($$histo_size_ref{$_}/1024), &fldw($graph_size));
	$x4 = &intfmt ($$histo_visits_ref{$_}, &fldw($graph_visits));
	$x2 = &intfmt ($n, &fldw($graph_hits));
	if ($main::html) {
	    $barn *= $main::hbw;
	    print REPORT "<tr><td>$x1</td><td align=right>$x4</td><td align=right>$x3</td><td align=right>$x2</td><td>";
	    print REPORT "<img src=\"redpix.gif\" alt=\"\" width=$barn height=$main::hbh>" if $barn > 0;
	    print REPORT "</td></tr>\n";
	} else {
	    $bar = '*' x $barn;
	    print REPORT "$x1  $x4  $x3  $x2  $bar\n";
	}				# if $main::html
	last if $nx-- <= 0;
    }				# foreach
    print REPORT "</table></div>\n" if $main::html;
    close REPORT;
} # print_histogram_report

#----------------------------------------------------------------
# print_h2 (head, tag)
# print a subheading
sub print_h2 {
    my $hed = shift;
    my $tag = shift;
use strict;    

    if ($main::html == 1) {
	print REPORT "<a name=\"$tag\">&nbsp;</a>\n\n" if $tag ne "";
	print REPORT "<h2>$hed</h2>\n";
    } else {
	print REPORT "\n\n$hed\n\n";
    }
} #print_h2

#----------------------------------------------------------------
# print_legend (head)
# print a DIV, then a legend for hit types, then open a table
# only called in html mode
# uses global: hbh (heading box height), hittype_names, gifnames
sub print_legend {
    my $hed = shift;
    my $gif;
use strict;    

    print REPORT "<div class=\"chart\">\n";
    print REPORT $hed;
    for (@main::hittype_names) {
	$gif = $main::gifnames{$_};
	print REPORT "<img src=\"$gif\" alt=\"\" width=$main::hbh height=$main::hbh> $_&nbsp;&nbsp;";
    } # for
    print REPORT "\n";
    print REPORT "<table summary=\"\">\n";
} #print_legend

#----------------------------------------------------------------
# print_pie_chart (\%counters, heading)
# represent a pie chart
# In HTML mode, call an applet
# In ASCII mode, print a bar of 100 chars, stacked by the type
sub print_pie_chart {
    my $counts_by_type_ref = shift;
    my $heading = shift;
    my ($bar, $i, $xx, $yy, $zz, $chr, $total, $percent);
use strict;    

    $total = 0;
    foreach (keys %$counts_by_type_ref) {
	$total += $$counts_by_type_ref{$_};
    }
    if ($total == 0) {
    	print REPORT "No $heading activity";
    	return;
    }

    if ($main::html && ($main::javapie eq 'yes')) { # Call on java applet
	print REPORT "<applet name=\"Pie\" code=\"Pie.class\" width=\"250\" height=\"300\">\n";
	print REPORT "    <param name=\"title\" value =\"$heading\">\n";
	$i = 0;
	foreach $yy (keys %$counts_by_type_ref) {
	    $xx = $$counts_by_type_ref{$yy};
	    if ($xx > 0) {
		$percent = int(100*$xx/$total);
		print REPORT "    <param name=\"arg$i\" value =\"$xx,$percent\% $yy\">\n";
		$i++;
	    }
	} # foreach
    } # if $main::html

    print REPORT "<br>\n" if $main::html;
    print REPORT "$heading  (";
    $i = 0;
    foreach $yy (keys %$counts_by_type_ref) {
	$chr = substr ("01234567890abcdefghijklmnopqrstuvwxyz", $i++, 1);
	$zz = &escapeHtml($yy);
	print REPORT "$chr=$zz ";
    }
    print REPORT ")\n";
    print REPORT "<br>\n" if $main::html;
    $i = 0;
    foreach (keys %$counts_by_type_ref) {
	$chr = substr("01234567890abcdefghijklmnopqrstuvwxyz", $i++, 1);
	$xx = int(100*$$counts_by_type_ref{$_}/$total);
	$bar = $chr x $xx;	# If browser doesn't have Java, sees line, same as text mode 
	print REPORT "$bar";
    }
    print REPORT "\n";
    print REPORT "<br>\n</applet>\n" if $main::html && ($main::javapie eq 'yes');

} # print_pie_chart

#----------------------------------------------------------------
# reversedns(domain) translates numeric URLs into names
# .. caches its result in an assoc array, 
# .. which is written out at program termination
sub reversedns {
    my $dom = shift;
    my(@adr, $arg, $ali, $typ, $len, @ads);
    my $nam = $dom;
    # Read the DNS cache if we haven't read it yet.
    if ($main::dnscache_read == 0) {
	if ($main::dnscache_file ne '') {
	    if (open(DNSCACHE, $main::dnscache_file)) {
		binmode DNSCACHE;
		while (<DNSCACHE>) {
		    chop;
		    ($arg, $num, $dom) = split (/ /, $_);
		    $main::dnscache{$num} = $dom;
		    $main::dnscache_arg{$num} = $arg;
		} # while
		close (DNSCACHE);
	    } # if open
	} # if dnscache_file
	$main::dnscache_read++;
    } # if dnscache_read

    if ($main::dnscache{$dom}) {      # in cache?
	return $main::dnscache{$dom}; # yes
    } else {			      # not in cache
	@adr = split(/\./, $dom);
	$arg = pack('C4', $adr[0], $adr[1], $adr[2], $adr[3]);
	($nam, $ali, $typ, $len, @ads) = gethostbyaddr($arg, 2);
	if ($nam eq '') {
	    $nam = $dom;	# failed, don't try again
	}
	$main::dnscache{$dom} = $nam; # remember result either way
	$main::dnscache_arg{$dom} = $arg;
    } # not in cache
    return $nam;
} #reversedns

#----------------------------------------------------------------
# lookup_geoip(domain) translates numeric URLs into 2 letter country names
sub lookup_geoip {
    my $dom = shift;
    my $nam = '';
    my $ans = '';
    my $i;
    if ($main::geon == 0) {
	&read_geoip();
    }
    if ($dom =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
	if ($main::geoipcache{$dom}) {      # in cache?
	    return $main::geoipcache{$dom}; # yes
	} else {
	    my $numval = $4 + 256*($3 + 256*($2 + 256*$1));
	    my $d = int(($main::geon+1)/2);
	    $i = $d;
	    my $min = 0;
	    my $max = $main::geon;
	    while (($i >= $min)&&($i < $max)&&($d > -3)) {
		my $lo = $main::geolo[$i];
		my $hi = $main::geohi[$i];
		my $cc = $main::geocc[$i];
		if (($lo <= $numval) && ($numval <= $hi)) {
		    $ans = $cc;
		    $ans =~ tr/A-Z/a-z/;
		    last;
		} elsif ($numval < $lo) {
		    $max = $i;
		    $d = int($d/2);
		    if ($d <= 0) {
			$i--;
			$d--;
		    } else {
			$i -= $d;
		    }
		} elsif ($numval > $hi) {
		    $min = $i+1;
		    $d = int($d/2);
		    if ($d <= 0) {
			$i++;
			$d--;
		    } else {
			$i += $d;
		    }
		} else {
		    last;
		}
            }
	    $main::geoipcache{$dom} = $ans;
	} # not in cache
    } # if dom
    return $ans;
} #lookup_geoip

sub read_geoip {
    if (open(GEO, $main::geoip_file)) {
	while (<GEO>) {
	    if (/".*",".*","(.*)","(.*)","(.*)",".*"/) {
		my $lo = $1;
		my $hi = $2;
		my $cc = $3;
		$main::geolo[$main::geon] = $lo;
		$main::geohi[$main::geon] = $hi;
		$main::geocc[$main::geon] = $cc;
		$main::geon++;
	    } # if record
	} # while
	close GEO;
    } # if open
} # read_geoip

#----------------------------------------------------------------
# read_config ()
sub read_config {
# sets global: many variables in the configuration
    my $the_config_file = shift;
    my $cmd;
    my $value;
    my $v1;
    my $line;
use strict;

    open (RCFILE, $the_config_file) or return;
    while (<RCFILE>) {
	$line = $_;
	chop;			# lose trailing NL

	if (/^\#/) {}		# comments
	elsif (/^\$(.*) = \"(.*)\";/) {
	    $cmd = $1;
	    $value = $2;
	    if ($cmd eq 'debug') {
		$main::debug = $value; # set debug switch
	    } elsif ($cmd eq 'site_name') {
		$main::site_name = $value; # site name
	    } elsif ($cmd eq 'preamble') {
		$main::preamble = $value; # file copied in at top
	    } elsif ($cmd eq 'postamble') {
		$main::postamble = $value; # file copied in at bottom
	    } elsif ($cmd eq 'log_file') {
		$main::log_file = $value; # name of the input log file
	    } elsif ($cmd eq 'output_file') {
		$main::output_file = $value; # name of the output file
	    } elsif ($cmd eq 'return_URL') {
		$main::return_URL = $value; # URL to return from html report
	    } elsif ($cmd eq 'mailto_address') {
		$main::mailto_address = $value; # email address for mailed report
	    } elsif ($cmd eq 'mail_program') {
		$main::mail_program = $value; # location of system's mail program
	    } elsif ($cmd eq 'summary_lines') {
		$main::month_days = $value; # number of days to summarize
	    } elsif ($cmd eq 'expire_time') {
		$main::expire_time = $value; # elapsed time until "visit" ended
	    } elsif ($cmd eq 'show_directories') {
		$main::show_directories = $value; # display paths 
	    } elsif ($cmd eq 'hotlink_html_prefix') {
		$main::hotlink_html_prefix = $value; # make filenames a hotlink
	    } elsif ($cmd eq 'count_pages') {
		$main::count_pages = $value; # count *.html accesses
	    } elsif ($cmd eq 'count_gifs') {
		$main::count_gifs = $value; # count *.gif accesses
	    } elsif ($cmd eq 'count_pngs') {
		$main::count_pngs = $value; # count *.png accesses
	    } elsif ($cmd eq 'count_jpegs') {
		$main::count_jpegs = $value; # count *.jpg accesses
	    } elsif ($cmd eq 'count_csss') {
		$main::count_csss = $value; # count *.css accesses
	    } elsif ($cmd eq 'count_downloads') {
		$main::count_downloads = $value; #  *.exe/zip/Z/hqx/sit accesses
	    } elsif ($cmd eq 'count_sounds') {
		$main::count_sounds = $value; # count *.au/mp2/wav accesses
	    } elsif ($cmd eq 'count_javas') {
		$main::count_javas = $value; # count *.class accesses
	    } elsif ($cmd eq 'count_other') {
		$main::count_other = $value; # count other accesses
	    } elsif ($cmd eq 'count_notfound') {
		$main::count_notfound = $value; # count notfound accesses
	    } elsif ($cmd eq 'show_tldsum') {
		$main::show_tldsum = $value; # summarize by top level domain
	    } elsif ($cmd eq 'show_cum') {
		$main::show_cum = $value; # keep long term stats
	    } elsif ($cmd eq 'nshowcumtldvisits') {
		$main::nshowcumtldvisits = $value;	# number of cumulative visits by tld to show
	    } elsif ($cmd eq 'nshowbusycumpages') {
		$main::nshowbusycumpages = $value; # busy pages to show longterm
	    } elsif ($cmd eq 'nshowpages') {
		$main::nshowpages = $value; # pages to show in today's report
	    } elsif ($cmd eq 'nshowtopleveldomains') {
		$main::nshowtopleveldomains = $value;	# number of today's toplevel domains to show
	    } elsif ($cmd eq 'nshowbusydomains') {
		$main::nshowbusydomains = $value; # number of today's busy (full) domains to show
	    } elsif ($cmd eq 'nshowbrowserhits') {
		$main::nshowbrowserhits = $value; # number of today's browser hits to show
	    } elsif ($cmd eq 'nshowclasshits') {
		$main::nshowclasshits = $value; # number of today's visit classes to show
	    } elsif ($cmd eq 'nshowqueryhits') {
		$main::nshowqueryhits = $value; # number of today's query hits to show
	    } elsif ($cmd eq 'nshowreferrerhits') {
		$main::nshowreferrerhits = $value; # number of today's referrer hits to show
	    } elsif ($cmd eq 'nshowengine') {
		$main::nshowengine = $value; # number of today's engines to show
	    } elsif ($cmd eq 'nshowcumreferrers') {
		$main::nshowcumreferrers = $value;	# number of cumulative visits by referrer to show
	    } elsif ($cmd eq 'show_illegal_refers') {	 
		$main::show_illegal_refers = $value;
	    } elsif ($cmd eq 'show_referrer') {
		$main::show_referrer = $value;  # interesting referrers in details
	    } elsif ($cmd eq 'show_browser') {
		$main::show_browser = $value; # show report by browser
	    } elsif ($cmd eq 'show_class') {
		$main::show_class = $value; # show report by visit class
	    } elsif ($cmd eq 'show_engine') {
		$main::show_engine = $value; # show report by search engine
	    } elsif ($cmd eq 'show_query') {
		$main::show_query = $value; # show report by query string
	    } elsif ($cmd eq 'show_visit_list') {
		$main::show_visit_list = $value; # show the list of visits
	    } elsif ($cmd eq 'show_each_hit') {
		$main::show_each_hit = $value; # show each hit in detail
	    } elsif ($cmd eq 'show_analysis') {
		$main::show_analysis = $value; # show derived figures
	    } elsif ($cmd eq 'show_retcodes') {
		$main::show_retcodes = $value; # show return code summary
	    } elsif ($cmd eq 'show_verbs') {
		$main::show_verbs = $value; # show verb tally
	    } elsif ($cmd eq 'show_referrer_hist') {
		$main::show_referrer_hist = $value; # keep a log of referrers
	    } elsif ($cmd eq 'html_types') {
		$main::html_types = $value; # which files are HTML
	    } elsif ($cmd eq 'nodetails_extensions') {
		$main::nodetails_extensions = $value; # which files are omitted from details
	    } elsif ($cmd eq 'nocumpage_extensions') {
		$main::nocumpage_extensions = $value; # which files are omitted from cumpage
	    } elsif ($cmd eq 'sound_extensions') {
		$main::sound_extensions = $value; # which files are sounds
	    } elsif ($cmd eq 'download_extensions') {
		$main::download_extensions = $value; # which files are downloads
	    } elsif ($cmd eq 'sourcefile_extensions') {
		$main::sourcefile_extensions = $value; # which files are sourcefiles
	    } elsif ($cmd eq 'show_indexer_details') {
		$main::show_indexer_details = $value; # show sessions if indexer
	    } elsif ($cmd eq 'do_reverse_dns') {
		$main::do_reverse_dns = $value; # look up numeric domains
	    } elsif ($cmd eq 'do_geoip') {
		$main::do_geoip = $value; # look up numeric domains
	    } elsif ($cmd eq 'dnscache_file') {
		$main::dnscache_file = $value; # DNS cache filename
	    } elsif ($cmd eq 'geoip_file') {
		$main::geoip_file = $value; # GEOIP CSV file name
	    } elsif ($cmd eq 'show_browser_in_details') {
		$main::show_browser_in_details = $value; # show browser if wanted
	    } elsif ($cmd eq 'stylesheet') {
		$main::stylesheet = $value; # external stylesheet
	    } elsif ($cmd eq 'min_details_session') {
		$main::min_details_session = int($value); # minimum session size v23
	    } elsif ($cmd eq 'cumulate_search_terms') {
		$main::cumulate_search_terms = $value; # default is YES v23
	    } elsif ($cmd eq 'javapie') {
		$main::javapie = $value; # default is YES v23
	    } elsif ($cmd eq 'kill_referrer') {
		$main::kill_referrer[++$main::nkill_referrer] = $value;
	    } elsif ($cmd eq 'ignore_hits_from') {
		$main::ignore_hits_from[++$main::nignore_hits_from] = $value;
	    } elsif ($cmd eq 'special_domain') {
		$main::special_domain[++$main::nspecial_domain] = $value;
	    } elsif ($cmd eq 'robot') {
		$main::robot[++$main::nrobot] = $value;
	    } elsif ($cmd eq 'robotdomain') { # from Ben v23
		$main::robotdom[++$main::nrobotdom] = $value;
            } elsif ($cmd eq 'pre_url') { # from Ned
                $main::pre_url[++$main::npre_url] = $value;
            } elsif ($cmd eq 'pre_file') {
                $main::pre_file[++$main::npre_file] = $value;
            } elsif ($cmd eq 'pre_domain') {
                $main::pre_domain[++$main::npre_domain] = $value;
            } elsif ($cmd eq 'pre_referrer') {
                $main::pre_referrer[++$main::npre_referrer] = $value;
	    } elsif ($cmd eq 'wars') {
		$main::wars[++$main::nbrowser_wars] = $value;
	    } elsif ($cmd eq 'platform') {
		$main::platform_wars[++$main::nplatform_wars] = $value;
	    } elsif ($cmd eq 'headpage') {
		$main::headpage[++$main::nheadpage] = $value;
	    } elsif ($cmd eq 'max_referrer_length') {
		$main::max_referrer_length = $value;
	    } elsif ($cmd eq 'max_query_length') {
		$main::max_query_length = $value;
	    } elsif ($cmd eq 'max_browser_length') {
		$main::max_domain_length = $value;
	    } elsif ($cmd eq 'max_domain_length') {
		$main::max_browser_length = $value;
	    } elsif ($cmd eq 'class') { # visitclass = "security.html:security,tvv,multics"
		if ($value =~ /^(.+):(.+)$/) {
		    $main::page_class{$1} = $2;
		}
	    } elsif ($cmd eq 'search') {
		if ($value =~ /^(.+)\?(.+)\?(.+)$/) {
		    $main::engine_name[++$main::nengines] = $1;
		    $main::engine_detector[$main::nengines] = $2;
		    $main::engine_query[$main::nengines] = $3;
		}
	    } elsif ($cmd eq 'inred') {
		$main::inred[++$main::ninred] = $value;
		$main::inredclass[$main::ninred] = 'inred';
	    } elsif ($cmd eq 'filedisplay') { # $filedisplay = "inred,foo.html"; v23
		($v1,$value) = split(/,/, $value);
		$main::inred[++$main::ninred] = $value;
		$main::inredclass[$main::ninred] = $v1;
	    } elsif ($cmd eq 'rettype') { # from Ned, modified v23
		if ($value =~ /^([0-9]+):([0-9]+):(.*)$/) { # $rettype = "404:2:fnf";
		    $main::rettype{$1} = $2;
		    $main::retcolor{$1} = $3;
		}
		if ($value =~ /^([0-9]+):([0-9]+)$/) { # $rettype = "302:2";
		    $main::rettype{$1} = $2;
		}
	    } else {
		print "Unknown command: $line" if $main::debug;
	    }
	} else {
	    print "Malformed command: $line" if $main::debug;
	}

    } # while
    close (RCFILE);

} # read_config
