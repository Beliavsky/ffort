implicit none
character(*),parameter::a(2,2)=reshape(["ab","cd","ef","gh"],[2,2])
print '(a)',a//":"
end
