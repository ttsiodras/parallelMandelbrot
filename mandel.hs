import Data.Char
import System
import System.IO
import Control.Parallel
import Control.Parallel.Strategies

-- Mini complex library (I want to understand the language, so no library-based complex)
data Complex = ComplexVal !Float !Float deriving (Show)
addC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a+c) (b+d)
subC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a-c) (b-d)
mulC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a*c-b*d) (a*d+b*c)
mulI c i = c `mulC` ComplexVal (fromIntegral i) 0.0
real (ComplexVal a _) = a
imag (ComplexVal _ b) = b
lengthC' (ComplexVal a b) = a*a + b*b
lengthC = sqrt . lengthC'

-- Mandelbrot inner loop: 
-- iteration number, accumulated Complex so far, 
-- Complex we are working on (pixel coordinates)
mandelImpl :: Int -> Complex -> Complex -> Int
mandelImpl i ac c 
    | i == 120           = 0
    | lengthC' ac' > 4.0 = i
    | otherwise = mandelImpl (i+1) ac' c
    where ac' = ac `mulC` ac `addC` c -- C_{n+1} = C_n * C_n + C_pixel

-- Bootstrap the calculation
mandel :: Complex -> Int
mandel = mandelImpl 0 (ComplexVal 0.0 0.0)

-- Prepend the PNM header before, and reverse the scanlines 
-- (since we start from the bottom)
emitPNM :: [Int] -> String
emitPNM = 
    (++) ("P5\n" ++ show width ++ " " ++ show height ++ "\n255\n") . map chr

width, height :: Int
width  = 800
height = 600

bottomLeft   = ComplexVal (-2.0) (-1.2)
upRight      = ComplexVal 1.2 1.2
horizStep    = 
    ComplexVal (real (upRight `subC` bottomLeft) / fromIntegral width) 0.0
vertStep     = 
    ComplexVal 0.0 (imag (upRight `subC` bottomLeft) / fromIntegral height)

mandelXY x y = 
    mandel (bottomLeft `addC` (vertStep `mulI` y) `addC` (horizStep `mulI` x))

mandelData = [let m = map (flip mandelXY y) [1 .. width]
              in m `using` seqList rwhnf `pseq` m
                  | y <- [height, height - 1 .. 1]
             ]

main = do
  hSetEncoding stdout latin1
  let is = parBuffer 64 rwhnf mandelData
  putStrLn $ emitPNM $ concat is
