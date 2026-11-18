program p
implicit none
real::a(4)=[2.,0.,4.,0.],b(4)=-1.
where(a/=0.) b=8./a
print *,b
end program
