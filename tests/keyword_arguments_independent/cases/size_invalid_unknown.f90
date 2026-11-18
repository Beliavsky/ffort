program keyword_oracle
implicit none
integer :: aa(2),bb(2)
aa=1
bb=1
print *,777
print *,size(array=aa,no_such_keyword=1)
end program
