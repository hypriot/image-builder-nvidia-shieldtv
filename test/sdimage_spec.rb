require 'serverspec'
set :backend, :exec

describe file('image-release.txt') do
  it { should be_file }
  it { should be_mode 644 }
  its(:content) { should contain 'sd-image' }
  it { should be_owned_by 'root' }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /HYPRIOT_DEVICE=/ }
end
