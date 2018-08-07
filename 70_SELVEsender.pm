package main;
use strict;
use warnings;
use MIME::Base64 qw( decode_base64 encode_base64 );

my %SELVEsender_gets = (
    "getInfo"       => ["selve.GW.sender.getInfo",":noArg"],
    "getValues"     => ["selve.GW.sender.getValues",":noArg"]
);

my %SELVEsender_sets = (
    "setLabel"      => ["selve.GW.sender.setLabel",":textField"],
    "delete"        => ["selve.GW.sender.delete",":noArg"],
    "writeManual"   => ["selve.GW.sender.writeManual",""],
    "clear"         => ["clear",":noArg"],
    "reinit"        => ["reinit",":noArg"]
);

sub SELVEsender_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}      = 'SELVEsender_Define';
    $hash->{UndefFn}    = 'SELVEsender_Undef';
    $hash->{DeleteFn}   = 'SELVEsender_Delete';
    $hash->{SetFn}      = 'SELVEsender_Set';
    $hash->{GetFn}      = 'SELVEsender_Get';
    $hash->{AttrFn}     = 'SELVEsender_Attr';
    $hash->{ReadFn}     = 'SELVEsender_Read';
	$hash->{ParseFn}	= 'SELVEsender_Parse';
	
	$hash->{Match}     = "^SELVEsender@@.*";

    $hash->{AttrList} = "verbose room " . $readingFnAttributes;
}

sub SELVEsender_Define($$) {
    my ($hash, $def) = @_;
    my @param = split('[ \t]+', $def);
	
	my $name = $param[0];
    
    if(int(@param) != 3) {
        return "too few parameters: define <name> SELVEsender <SenderID>";
    }
    
	$hash->{AktorID} = $param[2];
	$hash->{maskdec} = 2 ** $param[2];
    my $Mask64 = encode_base64(pack("L2",$hash->{maskdec}));
	$Mask64 =~ s/\r//;
	$Mask64 =~ s/\n//;
	Log3 $hash, 5, "MASK: $Mask64";
	$hash->{maskbase64} = $Mask64;

    $modules{SELVEsender}{defptr}{$param[2]} = $hash;
    
	AssignIoPort($hash);
    #Log3 undef, 2, Dumper($hash);
    return undef;
}

sub SELVEsender_Delete($$) {
    my ( $hash, $name ) = @_;
    $modules{SELVEsender}{defptr}{$hash->{AktorID}} = undef;
    return undef;
}

sub SELVEsender_Parse($$) {
	my ($gwhash, $msg) = @_;
    my ($cmd,$devid) = split(/:/, $msg);
    $cmd =~ s/SELVEsender@@//;
   
    my $DevResp = '';
    my $key = '';
    my $State = '';
    
    #Log3 $hash, 2, "DEFS: " . Dumper(%defs);
    #Log3 $hash, 2, "Module: " . Dumper($modules{SELVEsender});
    
    my $hash = $modules{SELVEsender}{defptr}{$devid};
    if(!$hash)
    {
        DoTrigger("global","UNDEFINED SELVEsender_$devid SELVEsender $devid");
        Log3 $hash, 3, "SELVEsender UNDEFINED, code $devid";
        return "UNDEFINED SELVEsenderDeviceID $devid $msg";
    }

    my $name = $hash->{NAME};
    Log3 $hash, 3, "PARSE CALLED: $name, cmd: $cmd, SenderID: $devid";

    my $data = $data{SELVEresponse};

    if($cmd eq "selve.GW.sender.getInfo")
    {
        my $response = "SenderID: " . $data->{array}->{int}[0] . " | Funkadresse: " . $data->{array}->{int}[1] . " | ";
        $response .= "SenderName: " . $data->{array}->{string}[1];
        $hash->{DevInfo} = $response;
    } elsif ($cmd eq 'selve.GW.sender.getValues' or $cmd eq 'selve.GW.event.sender')
    {
        my @senderStateInfo = qw(Unknown DriveUp DriveDown Stop ZwPos1 ZwPos2 SavePos1 SavePos2 Auto Man KeyRelease Select Delete);
        readingsBeginUpdate($hash);
        readingsBulkUpdate($hash,"command",$data->{array}->{int}[1]);
        readingsBulkUpdate($hash,"state",$senderStateInfo[$data->{array}->{int}[1]]);
        readingsEndUpdate($hash, 1);
    }
        
    return $name; 
}

sub SELVEsender_Undef($$) {
    my ($hash, $arg) = @_; 
    # nothing to do
    return undef;
}

sub SELVEsender_Get($@) {
	my ($hash, $name, @param) = @_;
	
    return '"get SELVE" needs at least one argument' if (@param < 1);
	
    my $opt = shift @param;
	
    if(!$SELVEsender_gets{$opt}) {
        my @setparams = ();
        my $key;
        for $key (keys %SELVEsender_gets) {
            unshift @setparams, $key . $SELVEsender_gets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
    }
    
    my $cmd = $SELVEsender_gets{$opt}[0];
	
    Log3 $hash, 3, "GET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;
    
    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};
 	
    unshift(@param, $hash->{AktorID}); # einfügen AktorID
    unshift(@param, $cmd); # einfügen Commando
    IOWrite($hash, $cmd, @param);
    
 	return undef;
}

sub SELVEsender_Set($@) {
	my ($hash, $name, @param) = @_;
	
	return '"set SELVEsender" needs at least one argument' if (int(@param) < 1);
	
	my $opt = shift @param;
	
	if(!$SELVEsender_sets{$opt}) {
        my @setparams = ();
        my $key;
		for $key (keys %SELVEsender_sets) {
            unshift @setparams, $key . $SELVEsender_sets{$key}[1];
        }
        return "Unknown argument $opt, choose one of " . join(" ", @setparams);
	}
	
    my $cmd = $SELVEsender_sets{$opt}[0];

    Log3 $hash, 5, "SET-CMD: " . $cmd . " ; " . $hash->{AktorID} . " via " . $hash->{IODev}->{NAME} ;

    $hash->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastCommand"} = $cmd;
    $hash->{"IODev"}->{"lastAktorID"} = $hash->{"AktorID"};

	if($cmd =~ "selve.GW.sender.setLabel")
    {
        if (@param != 1)
            {
                return "set label needs an argument";
            }
        unshift(@param, $hash->{AktorID}); # einfügen AktorID
        unshift(@param, $cmd); # einfügen Commando
        Log3 $hash, 5, "CMD: $cmd with param: " . @param;
        IOWrite($hash, $cmd, @param);
    } elsif($cmd eq "reinit") {
        AssignIoPort($hash);
    } elsif($cmd eq "clear") {
        delete $hash->{"lastCommand"};
        delete $hash->{"DevInfo"};
    } 
    
    return undef;
}


sub SELVEsender_Attr(@) {
	my ($cmd,$name,$attr_name,$attr_value) = @_;
	Log3 undef, 5, "CMD: $cmd ; NAME: $name ; ATTRNAME: $attr_name ; ATTRVALUE: $attr_value";
    
	return undef;
}

1;

=pod
=begin html

<a name="SELVEsender"></a>
<h3>SELVEsender</h3>
<ul>
    <i>SELVEsender</i> defines a SELVE sender (remote control)
    <br><br>
    <p>This modul can be used to start arbitrary actions with your SELVE remote control (eg. "commeo Multi Send"). A separate instance is needed for each channel. Events will be generated for each keypress on the remote.</p>
    <a name="SELVEsenderDefine"></a>
    <b>Define</b>
    <ul>
        <code>define <name> SELVEsender &lt;SenderID&gt;</code>
         <br><br>
        SenderID (0 is channel number 1)
        <br><br>
        Example: <code>define SELVEmultisend_CH1 SELVEsender 0</code>

    </ul>
    <br>
    
    <a name="SELVEsenderSet"></a>
    <b>Set</b><br>
    <ul>

        <li><b>setLabel</b> - change sender name</li>
        <li><b>delete</b> - delete sender from gateway - no questions asked</li>
        <li><b>writeManual</b></li>
        <li><b>reinit</b> - reassign IO port</li>
    </ul>
    <br>

    <a name="SELVEsenderGet"></a>
    <b>Get</b><br>
    <ul>
        <li><b>getInfo</b> - Read info from sender (visible as Internal)</li>
        <li><b>getValues</b> - Read sender state (triggers events!)</li>
    </ul>
    <br>

    <b>Internals</b><br />
    <ul>
        <li><b>AktorID</b> - SELVE SenderID (starting from 0)</li>
        <li><b>DevInfo</b> - last response to getInfo command (formatted)</li>
        <li><b>LastCommand</b> - last command sent to sender</li>
    </ul>
    <br />

    <b>Generated Readings/Events</b><br />
    <ul>
        <li><b>command</b> - Numerical value of key being pressed</li>
        <li><b>state</b> - Text of key being pressed</li>
    </ul>
    <br />
    <b>List of possible keys:</b>
    <ol>
        <li>DriveUp</li>
        <li>DriveDown</li>
        <li>Stop</li>
        <li>Pos1 - drive to saved position #1</li>
        <li>Pos2 - drive to saved position #2</li>
        <li>SavePos1 - save current position as #1</li>
        <li>SavePos2 - save current position as #2</li>
        <li>Auto - Auto/Man switch set to Auto</li>
        <li>Man - Auto/Man switch set to Manual</li>
        <li>Name - name changed on sender</li>
        <li>KeyRelease - key released (only sent during training)</li>
        <li>Select - "select" pressed (back of remote)</li>
        <li>Delete - association has been deleted</li>
    </ol>
    
</ul>

=end html

=cut