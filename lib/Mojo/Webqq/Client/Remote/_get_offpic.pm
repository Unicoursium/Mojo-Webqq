use File::Temp qw/:seekable/;
sub Mojo::Webqq::Client::_get_offpic {
    my $self = shift;
    my $file_path = shift;
    my $from_uin  = shift;
    return  unless $self->has_subscribers("receive_offpic");
    my $api = 'http://w.qq.com/d/channel/get_offpic2';
    my @query_string = (
        file_path   =>  $file_path,
        f_uin       =>  $from_uin,
        clientid    =>  $self->clientid,  
        psessionid  =>  $self->psessionid,
    );
    my $callback = sub{
        my ($data,$ua,$tx) = shift;
        return  unless $self->has_subscribers("receive_offpic");
        return unless defined $data;
        return unless $tx->res->heades->content_type =~/^image\/(.*)/;
        my $type =      $1=~/jpe?g/i        ?   ".jpg"
                    :   $1=~/png/i          ?   ".png"
                    :   $1=~/bmp/i          ?   ".bmp"
                    :   $1=~/gif/i          ?   ".gif"
                    :                           undef
        ;
        return unless defined $type; 
        my $tmp = File::Temp->new(
                TEMPLATE    => "webqq_offpic_XXXX",    
                SUFFIX      => $type,
                TMPDIR      => 1,
                UNLINK      => 1,
        );
        binmode $tmp;
        print $tmp $response->content();    
        close $tmp;
        eval{
            open(my $fh,"<:raw",$tmp->filename) or die $!;
            $self->emit(receive_offpic => $fh,$tmp->filename);
            close $fh;
        };
        $self->error("[Mojo::Webqq::Client::_get_offpic] $@\n") if $@;
    };
    $self->http_get($self->gen_url($api,@query_string),$callback);
};
1;