use strictures;

package basic_test;

use Test::InDistDir;
use Test::More;
use Capture::Tiny 'capture';
use Test::Fatal;

use WebService::Plotly;

eval "use PDL";

run();
done_testing;
exit;

sub run {
    my %user = (
        un       => "api_test",
        key      => "key",
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
            Storable::store [ $x1, $y1 ], $pdl_data;
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
    my $email = $user->{email};
    $email =~ s/\@/\%40/;
    my $version = WebService::Plotly->version || '';
    my %pairs = (
        "/apimkacct / email=$email&un=$user->{un}&version=$version&platform=Perl" =>
qq[{"api_key": "$user->{key}", "message": "", "un": "$user->{un}", "tmp_pw": "$user->{password}", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3Anull%7D&un=$user->{un}&version=$version&origin=plot&args=%5B%5B1%2C2%2C3%2C4%5D%2C%5B10%2C15%2C13%2C17%5D%2C%5B2%2C3%2C4%2C5%5D%2C%5B16%2C5%2C11%2C9%5D%5D&platform=Perl&key=$user->{key}"

          => qq[{"url": "https://plot.ly/~$user->{un}/0", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/0 or inside your plot.ly account where it is named 'plot from API'", "warning": "", "filename": "plot from API", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3A%22plot+from+API%22%7D&un=$user->{un}&version=$version&origin=plot&args=%5B%7B%22pointpos%22%3A-1.8%2C%22y%22%3A%5B1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%2C1%5D%2C%22boxpoints%22%3A%22all%22%2C%22jitter%22%3A0.3%2C%22type%22%3A%22box%22%7D%5D&platform=Perl&key=$user->{key}"
          => qq[{"url": "https://plot.ly/~$user->{un}/1", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/1 or inside your plot.ly account where it is named 'plot from API (1)'", "warning": "", "filename": "plot from API (1)", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3A%22plot+from+API+(1)%22%7D&un=$user->{un}&version=$version&origin=plot&args=%5B%5B0%2C1.28228271575094%2C2.56456543150187%2C3.84684814725281%2C5.12913086300374%2C6.41141357875468%2C7.69369629450562%2C8.97597901025655%2C10.2582617260075%2C11.5405444417584%2C12.8228271575094%2C14.1051098732603%2C15.3873925890112%2C16.6696753047622%2C17.9519580205131%2C19.234240736264%2C20.516523452015%2C21.7988061677659%2C23.0810888835168%2C24.3633715992678%2C25.6456543150187%2C26.9279370307697%2C28.2102197465206%2C29.4925024622715%2C30.7747851780225%2C32.0570678937734%2C33.3393506095243%2C34.6216333252753%2C35.9039160410262%2C37.1861987567771%2C38.4684814725281%2C39.750764188279%2C41.03304690403%2C42.3153296197809%2C43.5976123355318%2C44.8798950512828%2C46.1621777670337%2C47.4444604827846%2C48.7267431985356%2C50.0090259142865%2C51.2913086300374%2C52.5735913457884%2C53.8558740615393%2C55.1381567772902%2C56.4204394930412%2C57.7027222087921%2C58.9850049245431%2C60.267287640294%2C61.5495703560449%2C62.8318530717959%5D%2C%5B0%2C0.843294627805856%2C0.422128698503034%2C-0.441226470165472%2C-0.547503487089109%2C0.0673517422367614%2C0.457366285904565%2C0.176828213301626%2C-0.265389780406003%2C-0.269674043959601%2C0.0703646298416577%2C0.243893188115149%2C0.0676384677126959%2C-0.154863929056215%2C-0.129858243347091%2C0.05482869629949%2C0.127928477398816%2C0.021611443873364%2C-0.0881715414468317%2C-0.0608587917241091%2C0.0377619990293321%2C0.0659943959757905%2C0.00381506496885814%2C-0.0491560023375872%2C-0.0275581151401661%2C0.0242415664367422%2C0.0334587771159902%2C-0.00200936014698983%2C-0.0268958480722349%2C-0.0119084571919307%2C0.0148506747745368%2C0.0166484433762141%2C-0.00315755789163243%2C-0.0144629574290807%2C-0.0047964523556046%2C0.00879030769874005%2C0.00811161194115449%2C-0.00274140367899917%2C-0.00764893974873858%2C-0.00170756920936203%2C0.0050639031844756%2C0.00385613988297645%2C-0.00198811948558657%2C-0.00397903179641911%2C-0.000453403047040574%2C0.00285196918046206%2C0.0017784507207353%2C-0.00131658072954927%2C-0.00203518684842697%2C-4.57376446929804e-018%5D%5D&platform=Perl&key=$user->{key}"
          => qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3A%22plot+from+API+(2)%22%7D&un=$user->{un}&version=$version&origin=style&args=%5B%7B%22line%22%3A%7B%22width%22%3A4%2C%22color%22%3A%22rgb(84%2C+39%2C+143)%22%7D%7D%5D&platform=Perl&key=$user->{key}"
          => qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3A%22plot+from+API+(2)%22%7D&un=$user->{un}&version=$version&origin=layout&args=%5B%7B%22width%22%3A600%2C%22titlefont%22%3A%7B%22color%22%3A%22rgb(84%2C+39%2C+143)%22%2C%22size%22%3A25%2C%22family%22%3A%22%5C%22Avant+Garde%5C%22%2C+Avantgarde%2C+%5C%22Century+Gothic%5C%22%2C+CenturyGothic%2C+%5C%22AppleGothic%5C%22%2C+sans-serif%22%7D%2C%22showlegend%22%3Anull%2C%22font%22%3A%7B%22color%22%3A%22rgb(84%2C+39%2C+143)%22%2C%22size%22%3A20%2C%22family%22%3A%22%5C%22Avant+Garde%5C%22%2C+Avantgarde%2C+%5C%22Century+Gothic%5C%22%2C+CenturyGothic%2C+%5C%22AppleGothic%5C%22%2C+sans-serif%22%7D%2C%22height%22%3A600%2C%22autosize%22%3Anull%2C%22title%22%3A%22Damped+Sinusoid%22%2C%22margin%22%3A%7B%22pad%22%3A2%2C%22l%22%3A70%2C%22r%22%3A40%2C%22b%22%3A60%2C%22t%22%3A60%7D%2C%22paper_bgcolor%22%3A%22rgb(188%2C+189%2C+220)%22%2C%22plot_bgcolor%22%3A%22rgb(158%2C+154%2C+200)%22%7D%5D&platform=Perl&key=$user->{key}"
          => qq[{"url": "https://plot.ly/~$user->{un}/2", "message": "High five! You successfuly sent some data to your account on plotly. View your plot in your browser at https://plot.ly/~$user->{un}/2 or inside your plot.ly account where it is named 'plot from API (2)'", "warning": "", "filename": "plot from API (2)", "error": ""}],
"/clientresp / kwargs=%7B%22fileopt%22%3Anull%2C%22filename%22%3A%22plot+from+API+(2)%22%7D&un=$user->{un}&version=$version&origin=layout&args=%5B%7B%7D%5D&platform=Perl&key=$user->{key}"
          => qq[{"url": "", "message": "", "warning": "", "filename": "", "error": "Traceback (most recent call last):\\n  File \\"/home/jp/dj/shelly/remote/remoteviews.py\\", line 311, in clientresp\\n    grph = {'layout': args[0]}\\nKeyError: 0\\n"}],
    );
    return sub {
        my ( $self, $request ) = @_;

        my $req_string = $request->uri->path . " / " . $request->content;

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
