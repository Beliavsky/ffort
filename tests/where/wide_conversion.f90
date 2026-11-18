program p
implicit none
integer(8)::a(3)=[3000000000_8,0_8,4000000000_8]
real(8)::b(3)=0.0_8
where(a/=0_8) b=a
print *,b
end program
