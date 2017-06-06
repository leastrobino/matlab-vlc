%
%  VLC.m
%
%  Created by Léa Strobino.
%  Copyright 2017. All rights reserved.
%

classdef VLC < matlab.mixin.SetGet
  
  properties (Constant)
    Port = 4212;
  end
  
  properties (SetAccess = private)
    Version
    Status
    Current
    Playlist
  end
  
  properties
    Loop
    Random
    Repeat
  end
  
  properties (GetAccess = private)
    Fullscreen
  end
  
  properties (Access = private)
    requestURL
    password = 'QvGkByH97AOxRvhP';
  end
  
  methods
    
    function this = VLC()
      persistent retry %#ok<*NASGU>
      this.requestURL = sprintf('http://127.0.0.1:%d/request.json',this.Port);
      try
        this.set('Fullscreen','off','Loop','off','Random','off','Repeat','off');
      catch e
        if ~(isempty(regexp(e.message,'java\.net\.ConnectException: Connection refused','once')) ...
            && isempty(regexp(e.message,'java\.net\.SocketTimeoutException: connect timed out','once'))) ...
            && isempty(retry)
          args = sprintf('--extraintf http --http-host localhost --http-port %d --http-password "%s" --http-src "%s"',...
            this.Port,this.password,fileparts(mfilename('fullpath')));
          if ispc
            if exist('C:\Program Files (x86)\VideoLAN\VLC\vlc.exe','file')
              [~,~] = dos(['"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" ' args ' &']);
            else
              [~,~] = dos(['"C:\Program Files\VideoLAN\VLC\vlc.exe" ' args ' &']);
            end
          elseif ismac
            [~,~] = unix(['open -a VLC --args ' args ' 2> /dev/null']);
          end
          pause(3);
          retry = true;
          this = VLC();
        else
          retry = [];
          error('VLC:CommunicationError','Unable to communicate with VLC.');
        end
      end
      retry = [];
    end
    
    function play(this,file)
      if nargin > 1
        this.request(['c=add&v=' this.urlencode(this.getFile(file))]);
      else
        this.request('c=play');
      end
    end
    
    function add(this,file)
      this.request(['c=enqueue&v=' this.urlencode(this.getFile(file))]);
    end
    
    function pause(this)
      this.request('c=pause');
    end
    
    function stop(this)
      this.request('c=stop');
    end
    
    function next(this)
      this.request('c=next');
    end
    
    function prev(this)
      this.request('c=prev');
    end
    
    function clear(this)
      this.request('c=clear');
    end
    
    function seek(this,position)
      this.request(sprintf('c=seek&v=%.0f',position));
    end
    
    function v = get.Version(this)
      v = this.getStatus().version;
    end
    
    function s = get.Status(this)
      s = this.getStatus().status;
    end
    
    function c = get.Current(this)
      r = this.getStatus();
      if isfield(r,'current')
        c = r.current;
        c.Meta = struct();
        m = fieldnames(r.current.Meta);
        for i = 1:length(m)
          n = lower(m{i});
          j = find(n == ' ' | n == '_');
          try %#ok<TRYNC>
            n([1 j+1]) = upper(n([1 j+1]));
          end
          n(j) = [];
          c.Meta.(n) = r.current.Meta.(m{i});
        end
      else
        c = [];
      end
    end
    
    function p = get.Playlist(this)
      p = this.getStatus().playlist;
    end
    
    function v = get.Loop(this)
      v = this.getValue('loop');
    end
    
    function set.Loop(this,loop)
      this.setValue('loop',loop);
    end
    
    function v = get.Random(this)
      v = this.getValue('random');
    end
    
    function set.Random(this,random)
      this.setValue('random',random);
    end
    
    function v = get.Repeat(this)
      v = this.getValue('repeat');
    end
    
    function set.Repeat(this,repeat)
      this.setValue('repeat',repeat);
    end
    
    function set.Fullscreen(this,fullscreen)
      this.setValue('fullscreen',fullscreen);
    end
    
  end
  
  methods (Access = private)
    
    function f = getFile(~,f)
      [p,n,e] = fileparts(f);
      if isempty(p)
        p = cd();
      end
      f = fullfile(p,[n e]);
      h = fopen(f);
      if h > 0
        fclose(h);
      else
        error('VLC:FileNotFound','"%s": no such file.',f);
      end
    end
    
    function s = getStatus(this)
      persistent t json
      if isempty(t) || toc(t) > .5
        json = json_decode(this.request());
        t = tic();
      end
      s = json;
    end
    
    function v = getValue(this,c)
      if this.getStatus().(c)
        v = 'on';
      else
        v = 'off';
      end
    end
    
    function setValue(this,c,v)
      if strcmpi(v,'on')
        this.request(['c=' c '&v=on']);
      elseif strcmpi(v,'off')
        this.request(['c=' c '&v=off']);
      else
        throwAsCaller(MException('MATLAB:datatypes:InvalidEnumValueFor',...
          'Invalid enum value. Use one of these values: ''on'' | ''off''.'));
      end
    end
    
    function s = request(this,r)
      persistent authorization isc
      if isempty(authorization)
        authorization = ['Basic ' org.apache.commons.codec.binary.Base64.encodeBase64(uint8([':' this.password]))'];
        isc = com.mathworks.mlwidgets.io.InterruptibleStreamCopier.getInterruptibleStreamCopier();
      end
      try
        if nargin == 2
          url = java.net.URL([this.requestURL '?' r]);
        else
          url = java.net.URL(this.requestURL);
        end
        c = url.openConnection();
        c.setConnectTimeout(50);
        c.setReadTimeout(500);
        c.setRequestProperty('Authorization',authorization);
        if nargin == 2
          c.setRequestMethod('HEAD');
          c.connect();
          c.getContentLength();
        else
          i = c.getInputStream();
          o = java.io.ByteArrayOutputStream();
          isc.copyStream(i,o);
          i.close();
          o.close();
          s = native2unicode(typecast(o.toByteArray()','uint8'),'UTF-8');
        end
      catch e
        if strcmp(e.identifier,'MATLAB:Java:GenericException')
          r = regexp(e.message,'\n([^\n]*)\n','tokens','once');
          error('VLC:SocketException',r{1});
        else
          rethrow(e);
        end
      end
    end
    
    function s = urlencode(~,s)
      s = char(java.net.URLEncoder.encode(s,'UTF-8'));
      s = strrep(s,'+','%20');
    end
    
  end
  
end
