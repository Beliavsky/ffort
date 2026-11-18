program p
integer,target::i,j
integer(kind=8),target::k
real,target::r
real(kind=8),target::d
logical,target::l
character(len=3),target::c
i=2;j=3;k=4000000000_8;r=1.5;d=2.25_8;l=.true.;c='abc'
print *,i,j,k,r,d,l,c
end program
