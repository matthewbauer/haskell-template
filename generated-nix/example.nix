{ mkDerivation, base, lib }:
mkDerivation {
  pname = "example";
  version = "0.1.0.0";
  src = throw "missing src definition";
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base ];
  license = "unknown";
  mainProgram = "example";
}
