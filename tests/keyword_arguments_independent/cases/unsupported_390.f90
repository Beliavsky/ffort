program keyword_oracle
implicit none
integer :: aa(2)
aa=1
print *,777
print *,lbound(array=aa,dim=1,kind=8)
end program
