print*,tail([10,20,30])
print*,tail([integer::])
print*,"seq(3)=",seq(3)," seq(1)=",seq(1)," seq(0)=",seq(0)," seq(-2)=",seq(-2)
call random_number(xsq)
write (*,"(/,'xsq=')")
do i=1,n
   write (*,"(100f10.4)") xsq(i,:)
end do
write (*,fmt_cr) "above_diag(xsq)",above_diag(xsq)
write (*,*) "'" // trim(now()) // "'"
xstr = trim(exe_name())
print*,"exe_name() = ",xstr
print*,and(.true.),and(.false.),and(.true.,.true.),and(.true.,.false.),and(.false.,.true.),and(.false.,.false.)
do i=1,nobs
   write (*,"(100i4)") i,partition(nobs,i)
end do
