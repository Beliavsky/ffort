print*,"'" // trim(strip(",boy,,girl,,,  ",",")) // "'"
print*,num_fields("boy,girl,,")
print*,num_fields("boy,girl,,",xstrip=.false.)
call random_seed()
call random_number(xvec)
xmat = matrix(xvec)
xvec_check = vector(xmat)
write (*,fmt_cr) "xvec",xvec
write (*,fmt_cr) "xvec_check",xvec_check
write (*,fmt_cr) "xmat",xmat
write (*,*) if_else(.true.,1.0_dp,0.0_dp),if_else(.false.,1.0_dp,0.0_dp)
write (*,*) if_else(.true.,1,0),if_else(.false.,1,0)
