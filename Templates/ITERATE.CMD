/* ITERATE.CMD */
do ix=1 to 10
     say ix': Always say this'
     if ix < 3 then iterate
     say ix':but only this if x > 2'
end
