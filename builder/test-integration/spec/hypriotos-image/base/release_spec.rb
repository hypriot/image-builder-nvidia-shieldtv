require 'spec_helper'

describe file('/etc/os-release') do
  it { should be_file }
  it { should be_owned_by 'root' }
  its(:content) { should match 'HYPRIOT_OS=' }
  its(:content) { should match 'HYPRIOT_TAG=' }
  its(:content) { should match 'HYPRIOT_DEVICE=' }

  its(:content) { should match 'HypriotOS/arm64' }
  its(:content) { should match 'NVIDIA ShieldTV' }
end
