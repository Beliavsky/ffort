program keyword_oracle
implicit none
integer :: aa(-2:2)
aa(-2)=1
aa(-1)=2
aa(0)=3
aa(1)=4
aa(2)=5
print *,maxval(dim=1,mask=aa(2:-2:-2)>1,array=aa(2:-2:-2))
end program
