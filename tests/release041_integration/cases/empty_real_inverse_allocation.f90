program p
implicit none
character(len=*),parameter :: fmt='(3(i0,1x))'
real(kind=8),allocatable::a(:)
a=asin([real(kind=8)::])
print fmt,size(a),kind(a),kind(atan([real(kind=8)::]))
a=atan(y=[real(kind=8)::],x=1.0_8)
write(*,fmt) size(a),kind(a),kind(real(a))
end program
