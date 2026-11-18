program keyword_oracle
implicit none
integer :: aa(-1:1,4:5)
aa=2
print *,size(dim=1,array=aa(1:-1:-1,:)),lbound(dim=2,array=aa+1),ubound(array=aa+1,dim=2)
end program
