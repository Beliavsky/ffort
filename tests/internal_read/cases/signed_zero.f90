program p
implicit none
character(20)::text
real::a
real(8)::b
text='-0 -0.0D0'
read(text,*) a,b
if(sign(1.0,a)/=-1.0.or.sign(1d0,b)/=-1d0) stop 1
print *,1
end program
