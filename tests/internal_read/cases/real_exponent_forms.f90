program p
implicit none
character(60)::text
real(8)::a(5)
text='1-2 2+2 +.5 -.25 3.e-1'
read(text,*) a
if(any(a/=[.01d0,200d0,.5d0,-.25d0,.3d0])) stop 1
print *,1
end program
