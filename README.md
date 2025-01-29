<h1><a href="https://nix.dev/manual/nix/2.25/protocols/nix-archive">nix archive (<i>&#42;.nar</i>)</a> <a href="https://github.com/doublecmd/doublecmd">double commander</a> packer plugin (unpack only)</h1>
<h2>how to install</h2>
<p>note: double commander doesn't copy plugin file, don't delete <code>nix-archive-doublecmd-linux-amd64.wcx</code> after installing</p>
<ol>
<li>download <code>nix-archive-doublecmd-linux-amd64.wcx</code> from <a href="https://github.com/xBZZZZ/nix-archive-doublecmd/releases/latest">latest release</a> or compile source code</li>
<li>open double commander <code>Options</code> window</li>
<li>select <code>Plugins WCX</code> left (&larr;) side</li>
<li>click <code>Add</code></li>
<li>open <code>nix-archive-doublecmd-linux-amd64.wcx</code> in file picker</li>
<li>type <code>nar</code> in <code>Enter extension</code> window and click <code>OK</code></li>
<li>click <code>OK</code> in <code>Options</code> window</li>
</ol>
<h2>how to compile source code</h2>
<p>note: don't use paths with shell or makefile special characters (like space)</p>
<ol>
<li>create folder where <code>nix-archive-doublecmd-linux-amd64.wcx</code> and intermediary files will be created:<pre lang="bash">mkdir /tmp/asd</pre></li>
<li><pre lang="bash">cd /tmp/asd</pre></li>
<li>download and extract <code>zig</code> compiler binary from https://ziglang.org/download/</li>
<li>download this repo:<pre lang="bash">git clone --depth=1 https://github.com/xBZZZZ/nix-archive-doublecmd.git</pre></li>
<li>compile <code>nix-archive-doublecmd-linux-amd64.wcx</code>:<pre lang="bash">nix-archive-doublecmd/makefile zig=/tmp/asd/zig-linux-x86_64-0.14.0-dev.2851+b074fb7dd/zig</pre>(replace <code>/tmp/asd/zig-linux-x86_64-0.14.0-dev.2851+b074fb7dd/zig</code> with <code>zig</code> executable path)</li>
</ol>