require 'serverspec'
set :backend, :exec

describe file('/workdir/hypriot-nvidia-shieldtv.img') do
  it { should be_file }
end

describe file('image-release.txt') do
  it { should be_file }
  it { should be_mode 644 }
  its(:content) { should contain 'sd-card-image' }
  it { should be_owned_by 'root' }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /HYPRIOT_DEVICE=/ }
end
