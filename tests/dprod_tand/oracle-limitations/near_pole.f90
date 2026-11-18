program probe
implicit none
real(8)::x,pi
real::z
pi=3.14159265358979323846264338327950288d0
x=nearest(90d0,-1d0)
write(*,'(es26.17)') x,tand(x),tand(89.99999999999999d0),1d0/tan((90d0-x)*pi/180d0)
x=nearest(90d0,1d0)
write(*,'(es26.17)') x,tand(x),tand(90.00000000000001d0),1d0/tan((90d0-x)*pi/180d0)
z=-0.0
print *,sign(1.0,tand(z)),sign(1.0,tand(-0.0))
end program
