program p
implicit none
character(50)::text
real::x
real(8)::y,z
text='16777217 16777217 .125D+1'
read(text,*) x,y,z
if(x/=16777216.0.or.y/=16777217d0.or.z/=1.25d0) stop 1
print *,1
end program
