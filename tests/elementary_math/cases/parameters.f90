program p
implicit none
integer(8),parameter::a=dim(10_8,-3_8),b=sign(-7_8,0_8)
real(8),parameter::g=log_gamma(4d0)
print *,a,b,g,kind(a),kind(g)
end program
