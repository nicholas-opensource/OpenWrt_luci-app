local kernel_version = luci.sys.exec("echo -n $(uname -r)")

m = Map("turboacc")
m.title	= translate("Turbo ACC Acceleration Settings")
m.description = translate("Opensource Flow Offloading driver (Fast Path or Hardware NAT)")

m:append(Template("turboacc/status"))

s = m:section(TypedSection, "turboacc", "")
s.addremove = false
s.anonymous = true

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/xt_FLOWOFFLOAD.ko") then
sw_flow = s:option(Flag, "sw_flow", translate("Software flow offloading"))
sw_flow.default = 0
sw_flow.description = translate("Software based offloading for routing/NAT")
sw_flow:depends("sfe_flow", 0)
end

if luci.sys.call("cat /proc/cpuinfo | grep -q MT76") == 0 then
hw_flow = s:option(Flag, "hw_flow", translate("Hardware flow offloading"))
hw_flow.default = 0
hw_flow.description = translate("Requires hardware NAT support. Implemented at least for mt76xx")
hw_flow:depends("sw_flow", 1)
end

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/fast-classifier.ko") then
sfe_flow = s:option(Flag, "sfe_flow", translate("Shortcut-FE flow offloading"))
sfe_flow.default = 0
sfe_flow.description = translate("Shortcut-FE based offloading for routing/NAT")
sfe_flow:depends("sw_flow", 0)
end

sfe_bridge = s:option(Flag, "sfe_bridge", translate("Bridge Acceleration"))
sfe_bridge.default = 0
sfe_bridge.description = translate("Enable Bridge Acceleration (may be functional conflict with bridge-mode VPN server)")
sfe_bridge:depends("sfe_flow", 1)

if nixio.fs.access("/proc/sys/net/ipv6") then
sfe_ipv6 = s:option(Flag, "sfe_ipv6", translate("IPv6 Acceleration"))
sfe_ipv6.default = 0
sfe_ipv6.description = translate("Enable IPv6 Acceleration")
sfe_ipv6:depends("sfe_flow", 1)
end

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/tcp_bbr.ko") then
bbr_cca = s:option(Flag, "bbr_cca", translate("BBR CCA"))
bbr_cca.default = 0
bbr_cca.description = translate("Using BBR CCA can improve TCP network performance effectively")
end

if nixio.fs.access("/lib/modules/" .. kernel_version .. "/xt_FULLCONENAT.ko") then
fullcone_nat = s:option(Flag, "fullcone_nat", translate("FullCone NAT"))
fullcone_nat.default = 0
fullcone_nat.description = translate("Using FullCone NAT can improve gaming performance effectively")
end

dns_caching = s:option(Flag, "dns_caching", translate("DNS Caching"))
dns_caching.default = 0
dns_caching.rmempty = false
dns_caching.description = translate("Enable DNS Caching and anti ISP DNS pollution")

dns_caching_mode = s:option(ListValue, "dns_caching_mode", translate("Resolve DNS Mode"), translate("DNS Program"))
dns_caching_mode:value("1", translate("Using PDNSD to query and cache"))
if nixio.fs.access("/usr/bin/dnsforwarder") then
dns_caching_mode:value("2", translate("Using DNSForwarder to query and cache"))
end
if nixio.fs.access("/usr/bin/dnsproxy") then
dns_caching_mode:value("3", translate("Using DNSProxy to query and cache"))
end
dns_caching_mode.default = 1
dns_caching_mode:depends("dns_caching", 1)

dns_caching_dns = s:option(Value, "dns_caching_dns", translate("Upsteam DNS Server"))
dns_caching_dns.default = "114.114.114.114,114.114.115.115,223.5.5.5,223.6.6.6,180.76.76.76,119.29.29.29,119.28.28.28,1.2.4.8,210.2.4.8"
dns_caching_dns.description = translate("Muitiple DNS server can saperate with ','")
dns_caching_dns:depends("dns_caching", 1)

extra_dns = s:option(Flag, "extra_dns", translate("Extra DNSProxy"))
extra_dns.default = 0
extra_dns.rmempty = false
extra_dns.description = translate("Enable Extra DNSProxy work on 5335")
extra_dns:depends("dns_caching_mode", 3)

extra_dns_nov6 = s:option(Flag, "extra_dns_nov6", translate("Filter AAAA"))
extra_dns_nov6.default = 1
extra_dns_nov6.rmempty = false
extra_dns_nov6.description = translate("Extra DNSProxy Filter AAAA Result")
extra_dns_nov6:depends("extra_dns", 1)

extra_dns_server = s:option(Value, "extra_dns_server", translate("Extra DNS Server"))
extra_dns_server.default = "tls://dns.google,tls://1.1.1.1,202.141.162.123:5353"
extra_dns_server.description = translate("Muitiple DNS server can saperate with ','")
extra_dns_server:depends("extra_dns", 1)

return m
