program main
implicit none
integer(8) :: a(3)=[4000000000_8,-2_8,5000000000_8]
real(8) :: d(3)=[1.25_8,-2.0_8,3.5_8]
real :: s(3)=[1.5,-2.0,4.0]
print *, pack(a,a>0),kind(pack(a,a>0))
print *, pack(d,d>0.0_8),kind(pack(d,d>0.0_8))
print *, pack(s,s>0.0),kind(pack(s,s>0.0))
end program
