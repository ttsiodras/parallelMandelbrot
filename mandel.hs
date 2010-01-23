import System
import Control.Parallel.Strategies

-- Mini complex library (I want to understand the language, so no library-based complex)
data Complex = ComplexVal !Float !Float deriving (Show)
addC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a+c) (b+d)
subC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a-c) (b-d)
mulC (ComplexVal a b) (ComplexVal c d) = ComplexVal (a*c-b*d) (a*d+b*c)
mulI c i = c `mulC` ComplexVal (fromIntegral i) 0.0
real (ComplexVal a _) = a
imag (ComplexVal _ b) = b
lengthC (ComplexVal a b) = sqrt (a*a + b*b)

-- Mandelbrot inner loop: 
-- iteration number, accumulated Complex so far, Complex we are working on (pixel coordinates)
mandelImpl :: Int -> Complex -> Complex -> Int
mandelImpl iter ac c
    | iter > 120  = 0
    | otherwise   = let ac' = ac `mulC` ac `addC` c -- C_{n+1} = C_n * C_n + C_pixel
                    in if lengthC ac' > 2.0
                       then iter
                       else mandelImpl (iter+1) ac' c

-- Bootstrap the calculation
mandel :: Complex -> Int
mandel = mandelImpl 1 (ComplexVal 0.0 0.0)

-- Render the scanlines [[Int]] into PNM data ("1 1 3 4\n1 0 3 1\n...")
emitPNMdata :: [[Int]] -> String
-- emitPNMdata (xs:xss) = concat (List.intersperse " " [show x| x<-xs]) ++ "\n" ++ emitPNMdata xss
emitPNMdata (xs:xss) = unwords [show x| x<-xs] ++ "\n" ++ emitPNMdata xss
emitPNMdata [] = ""

-- Prepend the PNM header before, and reverse the scanlines (since we start from the bottom)
emitPNM :: [[Int]] -> String
emitPNM xss = "P2\n" ++ show (length (head xss)) ++ "\n" ++ show (length xss) ++ "\n255\n" ++ emitPNMdata (reverse xss)

horizPixels :: Int = 800
vertPixels :: Int  = 600
bottomLeft   = ComplexVal (0.0-2.0) (0.0-1.2)
upRight      = ComplexVal 1.2 1.2
horizStep    = ComplexVal (real (upRight `subC` bottomLeft) / fromIntegral horizPixels) 0.0
vertStep     = ComplexVal 0.0 (imag (upRight `subC` bottomLeft) / fromIntegral vertPixels)

mandelData   = [[mandel (bottomLeft `addC` (vertStep `mulI` y) `addC` (horizStep `mulI` x))
		    | x<-[1..horizPixels]] | y<-[1..vertPixels]]

-- mandelData'  = parBuffer 2 rwhnf mandelData

main = do
    [no_threads] <- fmap (map read) getArgs
    putStrLn $ emitPNM $ parBuffer no_threads rwhnf mandelData
