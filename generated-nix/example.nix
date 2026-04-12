{ mkDerivation, aeson, base, containers, lens, lens-aeson, lib, mtl
, pandoc, text
}:
mkDerivation {
  pname = "example";
  version = "0.1.0.0";
  src = throw "missing src definition";
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    aeson base containers lens lens-aeson mtl pandoc text
  ];
  license = "unknown";
  mainProgram = "example";
}
