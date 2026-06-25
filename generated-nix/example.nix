{ mkDerivation, aeson, array, base, binary, bytestring, containers
, directory, filepath, lens, lens-aeson, lib, mtl, pandoc, process
, random, stm, template-haskell, text, transformers, unix, vector
}:
mkDerivation {
  pname = "example";
  version = "0.1.0.0";
  src = throw "missing src definition";
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    aeson array base binary bytestring containers directory filepath
    lens lens-aeson mtl pandoc process random stm template-haskell text
    transformers unix vector
  ];
  license = "unknown";
  mainProgram = "example";
}
