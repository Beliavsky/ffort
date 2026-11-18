implicit none
character(*),parameter::a(2,2)=reshape([trim("ab "),trim("cd  "),trim("ef "),trim("gh ")],[2,2])
character(*),parameter::b(0,2)=reshape([trim("ab ")],[0,2])
print '(a)',a
print *,size(b)
end
