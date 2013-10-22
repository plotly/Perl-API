use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use Capture::Tiny 'capture';
use Test::Fatal;
use URI;

use WebService::Plotly;

eval "use PDL";

run();
done_testing;
exit;

sub run {
    my %user = (
        un       => "api_test",
        key      => "api_key",
        password => "password",
        email    => 'api@test.com',
    );

    # comment and fill this in to run real network tests
    # $user{un}  = '';
    # $user{key} = '';

    {
        no warnings 'redefine';
        *LWP::UserAgent::send_request = fake_responses( \&LWP::UserAgent::send_request, \%user );
    }

    ok my $login = WebService::Plotly->signup( $user{un}, $user{email} ), "signup request returned a response";
    is $login->{api_key}, $user{key},      "response contains the expected api key";
    is $login->{tmp_pw},  $user{password}, "response contains the expected temp password";

    # comment this in to run real network tests
    # $ENV{PLOTLY_TEST_REAL} = 1;

    ok my $py = WebService::Plotly->new( un => $user{un}, key => $user{key} ), "can instantiate plotly object";

    {
        my $url  = "https://plot.ly/~$user{un}/0";
        my $name = "plot from API";

        my $x0 = [ 1,  2,  3,  4 ];
        my $y0 = [ 10, 15, 13, 17 ];
        my $x1 = [ 2,  3,  4,  5 ];
        my $y1 = [ 16, 5,  11, 9 ];
        my ( $out, $err, $response ) = capture {
            $py->plot( $x0, $y0, $x1, $y1 );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";
    }

  SKIP: {
        skip "no PDL", 15 if !eval { require PDL };
        my $url  = "https://plot.ly/~$user{un}/1";
        my $name = "plot from API (1)";
        my $box  = {
            y         => ones( 50 ),
            type      => 'box',
            boxpoints => 'all',
            jitter    => 0.3,
            pointpos  => -1.8
        };
        my ( $out, $err, $response ) = capture {
            $py->plot( $box );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";
    }

  SKIP: {
        skip "no PDL", 15 if !eval { require PDL };
        require PDL::Constants;
        require Storable;
        require PDL::IO::Storable;

        my $url  = "https://plot.ly/~$user{un}/2";
        my $name = "plot from API (2)";

        my $pdl_data = "t/pdl_data";
        if ( !-f $pdl_data ) {
            my $x1 = zeroes( 50 )->xlinvals( 0, 20 * PDL::Constants::PI() );
            my $y1 = sin( $x1 ) * exp( -0.1 * $x1 );
            Storable::nstore [ $x1, $y1 ], $pdl_data;
        }

        my ( $x1, $y1 ) = @{ Storable::retrieve( $pdl_data ) };

        my ( $out, $err, $response ) = capture {
            $py->plot( $x1, $y1 );
        };
        is $out,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err, "", "no error output";
        ok $response, "plot request returned a response";
        is $response->{url},      $url,  "received correct url";
        is $response->{filename}, $name, "received correct filename";

        # Minimal styling of data
        my $datastyle = { 'line' => { 'color' => 'rgb(84, 39, 143)', 'width' => 4 } };

        my ( $out2, $err2, $response2 ) = capture {
            $py->style( $datastyle );
        };
        is $out2,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err2, "", "no error output";
        ok $response2, "plot request returned a response";
        is $response2->{url},      $url,  "received correct url";
        is $response2->{filename}, $name, "received correct filename";

        # Style the Layout
        my $fontlist = qq["Avant Garde", Avantgarde, "Century Gothic", CenturyGothic, "AppleGothic", sans-serif];

        my $layout = {
            'title'         => 'Damped Sinusoid',
            'titlefont'     => { 'family' => $fontlist, 'size' => 25, 'color' => 'rgb(84, 39, 143)' },
            'autosize'      => undef,
            'width'         => 600,
            'height'        => 600,
            'margin'        => { 'l' => 70, 'r' => 40, 't' => 60, 'b' => 60, 'pad' => 2 },
            'paper_bgcolor' => 'rgb(188, 189, 220)',
            'plot_bgcolor'  => 'rgb(158, 154, 200)',
            'font'       => { 'family' => $fontlist, 'size' => 20, 'color' => 'rgb(84, 39, 143)' },
            'showlegend' => undef
        };

        my ( $out3, $err3, $response3 ) = capture {
            $py->layout( $layout );
        };
        is $out3,
"High five! You successfuly sent some data to your account on plotly. View your plot in your browser at $url or inside your plot.ly account where it is named '$name'",
          "received verbose welcome message";
        is $err3, "", "no error output";
        ok $response3, "plot request returned a response";
        is $response3->{url},      $url,  "received correct url";
        is $response3->{filename}, $name, "received correct filename";

    }

    {
        my $url    = "https://plot.ly/~$user{un}/2";
        my $name   = "plot from API (2)";
        my $layout = {};
        $py->filename( $name );

        my ( $out3, $err3, $exception ) = capture {
            exception {
                $py->layout( $layout );
            };
        };
        is $out3,        "",                                              "no normal output";
        is $err3,        "",                                              "no error output";
        like $exception, qr/grph = \{'layout': args\[0\]\}\nKeyError: 0/, "proper exception";
    }

    return;
}

sub fake_responses {
    my ( $old, $user ) = @_;
    my $email    = $user->{email};
    my $version  = WebService::Plotly->version || '';
    my @req_vals = ( $user->{key}, $user->{un}, $version );
    my %pairs    = (
        sprintf( q|/apimkacct / {"email":"%s","platform":"Perl","un":"%s","version":"%s"}|,
            $user->{email}, $user->{un}, $version ) =>
qq[{"api_key": "$user->{key}", "message": "", "un": "$user->{un}", "tmp_pw": "$user->{password}", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[[1,2,3,4],[10,15,13,17],[2,3,4,5],[16,5,11,9]]","key":"%s","kwargs":"{\"filename\":null,\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/0", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/0 or inside your plot.ly account where it is named 'plot from API'", "warning": "", "filename": "plot from API", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"boxpoints\":\"all\",\"jitter\":0.3,\"pointpos\":-1.8,\"type\":\"box\",\"y\":[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]}]","key":"%s","kwargs":"{\"filename\":\"plot from API\",\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/1", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/1 or inside your plot.ly account where it is named 'plot from API (1)'", "warning": "", "filename": "plot from API (1)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[[0,1.28228271575094,2.56456543150187,3.84684814725281,5.12913086300374,6.41141357875468,7.69369629450562,8.97597901025655,10.2582617260075,11.5405444417584,12.8228271575094,14.1051098732603,15.3873925890112,16.6696753047622,17.9519580205131,19.234240736264,20.516523452015,21.7988061677659,23.0810888835168,24.3633715992678,25.6456543150187,26.9279370307697,28.2102197465206,29.4925024622715,30.7747851780225,32.0570678937734,33.3393506095243,34.6216333252753,35.9039160410262,37.1861987567771,38.4684814725281,39.750764188279,41.03304690403,42.3153296197809,43.5976123355318,44.8798950512828,46.1621777670337,47.4444604827846,48.7267431985356,50.0090259142865,51.2913086300374,52.5735913457884,53.8558740615393,55.1381567772902,56.4204394930412,57.7027222087921,58.9850049245431,60.267287640294,61.5495703560449,62.8318530717959],[0,0.843294627805856,0.422128698503034,-0.441226470165472,-0.547503487089109,0.0673517422367614,0.457366285904565,0.176828213301626,-0.265389780406003,-0.269674043959601,0.0703646298416577,0.243893188115149,0.0676384677126959,-0.154863929056215,-0.129858243347091,0.05482869629949,0.127928477398816,0.021611443873364,-0.0881715414468317,-0.0608587917241091,0.0377619990293321,0.0659943959757905,0.00381506496885814,-0.0491560023375872,-0.0275581151401661,0.0242415664367422,0.0334587771159902,-0.00200936014698983,-0.0268958480722349,-0.0119084571919307,0.0148506747745368,0.0166484433762141,-0.00315755789163243,-0.0144629574290807,-0.0047964523556046,0.00879030769874005,0.00811161194115449,-0.00274140367899917,-0.00764893974873858,-0.00170756920936203,0.0050639031844756,0.00385613988297645,-0.00198811948558657,-0.00397903179641911,-0.000453403047040574,0.00285196918046206,0.0017784507207353,-0.00131658072954927,-0.00203518684842697,-4.57376446929804e-018]]","key":"%s","kwargs":"{\"filename\":\"plot from API (1)\",\"fileopt\":null}","origin":"plot","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"line\":{\"color\":\"rgb(84, 39, 143)\",\"width\":4}}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"style","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{\"autosize\":null,\"font\":{\"color\":\"rgb(84, 39, 143)\",\"family\":\"\\\\\"Avant Garde\\\\\", Avantgarde, \\\\\"Century Gothic\\\\\", CenturyGothic, \\\\\"AppleGothic\\\\\", sans-serif\",\"size\":20},\"height\":600,\"margin\":{\"b\":60,\"l\":70,\"pad\":2,\"r\":40,\"t\":60},\"paper_bgcolor\":\"rgb(188, 189, 220)\",\"plot_bgcolor\":\"rgb(158, 154, 200)\",\"showlegend\":null,\"title\":\"Damped Sinusoid\",\"titlefont\":{\"color\":\"rgb(84, 39, 143)\",\"family\":\"\\\\\"Avant Garde\\\\\", Avantgarde, \\\\\"Century Gothic\\\\\", CenturyGothic, \\\\\"AppleGothic\\\\\", sans-serif\",\"size\":25},\"width\":600}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"layout","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
        sprintf(
q|/clientresp / {"args":"[{}]","key":"%s","kwargs":"{\"filename\":\"plot from API (2)\",\"fileopt\":null}","origin":"layout","platform":"Perl","un":"%s","version":"%s"}|,
            @req_vals ) =>
qq[{"url": "", "message": "", "warning": "", "filename": "", "error": "Traceback (most recent call last):\\n  File \\"/home/jp/dj/shelly/remote/remoteviews.py\\", line 311, in clientresp\\n    grph = {'layout': args[0]}\\nKeyError: 0\\n"}],
    );
    return sub {
        my ( $self, $request ) = @_;

        my $url = URI->new( 'http:' );
        $url->query( $request->content );
        my %form    = $url->query_form;
        my $content = JSON->new->utf8->convert_blessed( 1 )->canonical( 1 )->encode( \%form );

        my $req_string = $request->uri->path . " / " . $content;

        die "unknown request: " . $req_string if !$pairs{$req_string};

        if ( $pairs{$req_string} eq "make" ) {
            my $res = $self->$old( $request );
            return $res if $ENV{PLOTLY_TEST_REAL};
            $DB::single = $DB::single = 1;
            exit;
        }

        my $res = HTTP::Response->new( 200, "OK", undef, $pairs{$req_string} );

        return $res;
    };
}
