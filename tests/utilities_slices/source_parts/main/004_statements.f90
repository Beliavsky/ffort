write (*,"(100(1x,a))") quote("dog"),quote(" cat "),quote(" boy"),quote("girl ")
print*,reverse([10.0_dp,20.0_dp,30.0_dp])
xvec = normalize([(i**2,i=1,size(xvec))] * 1.0_dp)
print*,sum(xvec),xvec
tf = [.true.,.true.,.false.,.true.]
print*,tf,frac_true(tf)
tf = .true.
print*,tf,frac_true(tf)
tf = .false.
print*,tf,frac_true(tf)
print*,tail([10.0_dp,20.0_dp,30.0_dp])
print*,tail([real(kind=dp)::])
