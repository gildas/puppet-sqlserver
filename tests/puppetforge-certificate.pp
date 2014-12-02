exec {'certificate-download':
  command  => "((new-object net.webclient).DownloadFile('https://www.geotrust.com/resources/root_certificates/certificates/GeoTrust_Global_CA.pem','C:\\Windows\\Temp\\GeoTrust_Global_CA.pem'))",
  creates  => "C:\\Windows\\Temp\\GeoTrust_Global_CA.pem",
  provider => powershell,
}

exec {'certificate-add':
  command  => "certutil -addstore Root C:\\Windows\\Temp\\GeoTrust_Global_CA.pem",
  provider => powershell,
  require  => Exec['certificate-download'],
}
